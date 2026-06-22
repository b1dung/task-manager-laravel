<?php

namespace App\Http\Controllers;

use App\Models\Invite;
use App\Models\RefreshToken;
use App\Models\User;
use App\Services\AccountSecurityService;
use App\Services\AuthTokens;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Laravel\Socialite\Facades\Socialite;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    public function __construct(private readonly AuthTokens $tokens, private readonly AccountSecurityService $security) {}

    /** Public signup -> pending; invite token -> active immediately. */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'fullName' => ['required', 'string', 'min:2'],
            'password' => ['required', 'string', 'min:8'],
            'email' => ['nullable', 'email'],
            'token' => ['nullable', 'string'],
        ]);

        // ── Invite registration (account is active right away) ──────────────────
        if (! empty($data['token'])) {
            $invite = Invite::query()
                ->where('token_hash', hash('sha256', $data['token']))
                ->whereNull('accepted_at')
                ->where('expires_at', '>', now())
                ->first();

            if (! $invite) {
                throw ValidationException::withMessages(['token' => 'Invalid or expired invitation']);
            }

            $user = User::create([
                'email' => $invite->email,
                'password_hash' => Hash::make($data['password']),
                'full_name' => $data['fullName'],
                'role' => 'member',
                'role_id' => $invite->role_id,
                'is_active' => true,
                'email_verified_at' => now(),
            ]);
            $invite->update(['accepted_at' => now()]);

            return $this->authResponse($user, 'active');
        }

        // ── Public registration (pending admin approval) ────────────────────────
        if (empty($data['email'])) {
            throw ValidationException::withMessages(['email' => 'Email is required']);
        }
        if (User::where('email', $data['email'])->exists()) {
            throw ValidationException::withMessages(['email' => 'This email is already in use']);
        }

        $user = User::create([
            'email' => $data['email'],
            'password_hash' => Hash::make($data['password']),
            'full_name' => $data['fullName'],
            'role' => 'member',
            'is_active' => false,
        ]);

        return response()->ok(['status' => 'pending', 'user' => $user->toAuthArray()]);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'otp' => ['nullable', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();
        if (! $user || ! Hash::check($data['password'], $user->password_hash)) {
            return response()->json(['success' => false, 'message' => 'Incorrect email or password'], 401);
        }
        if (! $user->is_active) {
            // Frontend shows the "pending approval" notice on 403.
            return response()->json(['success' => false, 'message' => 'Account pending approval'], 403);
        }
        if ($user->two_factor_enabled && ! $this->security->verifyTwoFactor($user, $data['otp'] ?? null)) {
            return response()->json(['success' => false, 'message' => 'A valid two-factor authentication code is required'], 401);
        }

        return $this->authResponse($user, 'active');
    }

    public function refresh(Request $request): JsonResponse
    {
        $current = $this->tokens->findRefresh($request->cookie(AuthTokens::REFRESH_COOKIE));
        if (! $current) {
            return response()->json(['success' => false, 'message' => 'Invalid refresh token'], 401);
        }

        $current->update(['revoked_at' => now()]); // rotation: revoke the old token
        $user = $current->user;

        $access = $this->tokens->issueAccess($user);
        $refresh = $this->tokens->issueRefresh($user);

        return response()->ok(['accessToken' => $access])
            ->withCookie($this->tokens->refreshCookie($refresh));
    }

    public function logout(Request $request): JsonResponse
    {
        $current = $this->tokens->findRefresh($request->cookie(AuthTokens::REFRESH_COOKIE));
        $current?->update(['revoked_at' => now()]);
        $request->user()?->currentAccessToken()?->delete();

        return response()->ok(null)->withCookie($this->tokens->forgetCookie());
    }

    public function me(Request $request): JsonResponse
    {
        return response()->ok($request->user()->toAuthArray());
    }

    /** GET /me/permissions — effective permissions for the current user. */
    public function permissions(Request $request): JsonResponse
    {
        $user = $request->user();
        $role = $user->assignedRole;

        return response()->ok([
            'roleId' => $role?->id,
            'roleKey' => $role?->key,
            'permissions' => $role?->permissions ?? [],
        ]);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        $this->security->requestPasswordReset($data['email']);

        return response()->ok(null);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $data = $request->validate(['token' => ['required', 'string'], 'password' => ['required', 'string', 'min:8']]);
        $this->security->resetPassword($data['token'], $data['password']);

        return response()->ok(null);
    }

    public function verifyEmail(Request $request): JsonResponse
    {
        $data = $request->validate(['token' => ['required', 'string']]);
        $this->security->verifyEmail($data['token']);

        return response()->ok(null);
    }

    public function resendVerification(Request $request): JsonResponse
    {
        $this->security->sendVerification($request->user());

        return response()->ok(null);
    }

    public function sessions(Request $request): JsonResponse
    {
        $rows = RefreshToken::where('user_id', $request->user()->id)->whereNull('revoked_at')->where('expires_at', '>', now())->latest('created_at')->get();

        return response()->ok($rows->map(fn ($row) => ['id' => $row->id, 'createdAt' => $row->created_at?->toIso8601String(), 'expiresAt' => $row->expires_at?->toIso8601String()]));
    }

    public function revokeSession(Request $request, string $id): JsonResponse
    {
        RefreshToken::where('user_id', $request->user()->id)->whereKey($id)->update(['revoked_at' => now()]);

        return response()->ok(null);
    }

    public function revokeAllSessions(Request $request): JsonResponse
    {
        $this->security->revokeAll($request->user()->id);

        return response()->ok(null);
    }

    public function setupTwoFactor(Request $request): JsonResponse
    {
        return response()->ok($this->security->setupTwoFactor($request->user()));
    }

    public function enableTwoFactor(Request $request): JsonResponse
    {
        $data = $request->validate(['code' => ['required', 'digits:6']]);
        abort_unless($this->security->verifyTwoFactor($request->user(), $data['code']), 400, 'Invalid two-factor authentication code');
        $request->user()->update(['two_factor_enabled' => true]);

        return response()->ok(null);
    }

    public function disableTwoFactor(Request $request): JsonResponse
    {
        $data = $request->validate(['code' => ['required', 'digits:6']]);
        abort_unless($this->security->verifyTwoFactor($request->user(), $data['code']), 400, 'Invalid two-factor authentication code');
        $request->user()->update(['two_factor_enabled' => false, 'two_factor_secret' => null]);
        $this->security->revokeAll($request->user()->id);

        return response()->ok(null);
    }

    public function googleRedirect(): RedirectResponse
    {
        abort_unless(config('services.google.client_id') && config('services.google.client_secret'), 503, 'Google OAuth is not configured');

        return Socialite::driver('google')->stateless()->redirect();
    }

    public function googleCallback(): Response
    {
        abort_unless(config('services.google.client_id') && config('services.google.client_secret'), 503, 'Google OAuth is not configured');
        $profile = Socialite::driver('google')->stateless()->user();
        abort_unless($profile->getEmail(), 409, 'Google account has no email');
        $user = User::where('email', strtolower($profile->getEmail()))->first();
        if (! $user) {
            $user = User::create(['email' => strtolower($profile->getEmail()), 'password_hash' => Hash::make(Str::random(64)), 'full_name' => $profile->getName() ?: $profile->getEmail(), 'avatar_url' => $profile->getAvatar(), 'role' => 'member', 'is_active' => false, 'email_verified_at' => now()]);
        }
        $frontend = rtrim(config('app.frontend_url'), '/');
        if (! $user->is_active) {
            return redirect($frontend.'/login?pending=1');
        }
        $access = $this->tokens->issueAccess($user);
        $refresh = $this->tokens->issueRefresh($user);

        return redirect($frontend.'/auth/callback#accessToken='.rawurlencode($access))->withCookie($this->tokens->refreshCookie($refresh));
    }

    private function authResponse(User $user, string $status): JsonResponse
    {
        $access = $this->tokens->issueAccess($user);
        $refresh = $this->tokens->issueRefresh($user);

        return response()->ok([
            'status' => $status,
            'user' => $user->toAuthArray(),
            'accessToken' => $access,
            'refreshToken' => '', // refresh lives in the httpOnly cookie
        ])->withCookie($this->tokens->refreshCookie($refresh));
    }
}
