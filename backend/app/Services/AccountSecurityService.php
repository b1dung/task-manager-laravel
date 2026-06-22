<?php

namespace App\Services;

use App\Models\AccountToken;
use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AccountSecurityService
{
    public function __construct(private readonly MailService $mail, private readonly TotpService $totp) {}

    public function requestPasswordReset(string $email): void
    {
        $user = User::where('email', Str::lower(trim($email)))->first();
        if (! $user) {
            return;
        }
        $token = $this->createToken($user, 'password_reset', 30);
        $link = rtrim(config('app.frontend_url'), '/').'/reset-password?token='.urlencode($token);
        $this->mail->send($user->email, 'Reset your TaskBoard password', 'Reset your password: '.$link);
    }

    public function resetPassword(string $token, string $password): void
    {
        $row = $this->consume($token, 'password_reset');
        User::whereKey($row->user_id)->update(['password_hash' => Hash::make($password)]);
        $this->revokeAll($row->user_id);
    }

    public function sendVerification(User $user): void
    {
        if ($user->email_verified_at) {
            return;
        }
        $token = $this->createToken($user, 'email_verification', 1440);
        $link = rtrim(config('app.frontend_url'), '/').'/verify-email?token='.urlencode($token);
        $this->mail->send($user->email, 'Verify your TaskBoard email', 'Verify your email: '.$link);
    }

    public function verifyEmail(string $token): void
    {
        $row = $this->consume($token, 'email_verification');
        User::whereKey($row->user_id)->update(['email_verified_at' => now()]);
    }

    public function setupTwoFactor(User $user): array
    {
        $secret = $this->totp->secret();
        $user->update(['two_factor_secret' => Crypt::encryptString($secret), 'two_factor_enabled' => false]);
        $label = rawurlencode('TaskBoard:'.$user->email);

        return ['secret' => $secret, 'uri' => "otpauth://totp/{$label}?secret={$secret}&issuer=TaskBoard&digits=6&period=30"];
    }

    public function verifyTwoFactor(User $user, ?string $code): bool
    {
        if (! $user->two_factor_secret || ! $code) {
            return false;
        }
        try {
            return $this->totp->verify(Crypt::decryptString($user->two_factor_secret), $code);
        } catch (\Throwable) {
            return false;
        }
    }

    public function revokeAll(string $userId): void
    {
        RefreshToken::where('user_id', $userId)->whereNull('revoked_at')->update(['revoked_at' => now()]);
    }

    private function createToken(User $user, string $type, int $minutes): string
    {
        AccountToken::where('user_id', $user->id)->where('type', $type)->whereNull('used_at')->delete();
        $plain = bin2hex(random_bytes(32));
        AccountToken::create(['user_id' => $user->id, 'type' => $type, 'token_hash' => hash('sha256', $plain), 'expires_at' => now()->addMinutes($minutes)]);

        return $plain;
    }

    private function consume(string $plain, string $type): AccountToken
    {
        return DB::transaction(function () use ($plain, $type) {
            $row = AccountToken::where('token_hash', hash('sha256', $plain))->where('type', $type)->whereNull('used_at')->where('expires_at', '>', now())->lockForUpdate()->first();
            abort_unless($row, 400, 'Token is invalid or expired');
            $row->update(['used_at' => now()]);

            return $row;
        });
    }
}
