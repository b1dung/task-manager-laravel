<?php

namespace App\Http\Controllers;

use App\Models\Invite;
use App\Models\User;
use App\Services\MailService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class InviteController extends Controller
{
    public function __construct(private readonly MailService $mail) {}

    public function create(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email'], 'roleId' => ['nullable', 'uuid', 'exists:roles,id']]);
        $email = Str::lower(trim($data['email']));
        if (User::where('email', $email)->exists()) {
            throw ValidationException::withMessages(['email' => 'Email này đã có tài khoản']);
        }
        Invite::where('email', $email)->whereNull('accepted_at')->delete();
        $token = bin2hex(random_bytes(32));
        $invite = Invite::create([
            'email' => $email,
            'role_id' => $data['roleId'] ?? null,
            'token_hash' => hash('sha256', $token),
            'invited_by' => $request->user()->id,
            'expires_at' => now()->addDays(7),
        ])->load('role');
        $view = $this->view($invite);
        $view['link'] = rtrim(config('app.frontend_url', env('FRONTEND_URL', 'http://localhost:5173')), '/').'/register?token='.$token;

        // Send the invitation email. Don't fail the request if mail is down —
        // the admin still gets the link in the response to share manually.
        $view['emailSent'] = $this->sendInviteEmail($request, $invite, $view['link']);

        return response()->ok($view, 201);
    }

    private function sendInviteEmail(Request $request, Invite $invite, string $link): bool
    {
        $inviter = $request->user()->full_name ?: $request->user()->email;
        $appName = config('app.name', 'TaskBoard');
        $roleLine = $invite->role?->name ? 'Vai trò: '.$invite->role->name."\n" : '';
        $body = "Xin chào,\n\n"
            ."{$inviter} đã mời bạn tham gia {$appName}.\n"
            .$roleLine
            ."\nNhấn vào liên kết dưới đây để tạo tài khoản (hết hạn sau 7 ngày):\n{$link}\n\n"
            ."Nếu bạn không mong đợi email này, hãy bỏ qua.\n";

        try {
            $this->mail->send($invite->email, "Bạn được mời tham gia {$appName}", $body);

            return true;
        } catch (\Throwable $e) {
            report($e);

            return false;
        }
    }

    public function index(): JsonResponse
    {
        $items = Invite::with('role')->whereNull('accepted_at')->where('expires_at', '>', now())->latest('created_at')->get();

        return response()->ok($items->map(fn (Invite $invite) => $this->view($invite)));
    }

    public function revoke(string $id): JsonResponse
    {
        $invite = Invite::findOrFail($id);
        $invite->delete();

        return response()->ok(null);
    }

    public function validateToken(Request $request): JsonResponse
    {
        $token = (string) $request->query('token', '');
        $invite = $token === '' ? null : Invite::with('role')->where('token_hash', hash('sha256', $token))->whereNull('accepted_at')->where('expires_at', '>', now())->first();
        if (! $invite) {
            abort(400, 'Lời mời không hợp lệ hoặc đã hết hạn');
        }

        return response()->ok(['email' => $invite->email, 'roleName' => $invite->role?->name]);
    }

    private function view(Invite $invite): array
    {
        return ['id' => $invite->id, 'email' => $invite->email, 'roleId' => $invite->role_id, 'roleName' => $invite->role?->name, 'expiresAt' => $invite->expires_at?->toIso8601String(), 'createdAt' => $invite->created_at?->toIso8601String()];
    }
}
