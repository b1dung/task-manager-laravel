<?php

namespace App\Services;

use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Cookie\CookieJar;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Cookie;

/**
 * Issues short-lived access tokens (Sanctum, 60m) and rotating refresh tokens
 * (random string, SHA-256 hashed in DB, delivered as an httpOnly cookie, 30d).
 * The refresh token is the effective login-session lifetime (shown on the
 * account page); the 60m access token is silently refreshed in the background.
 */
class AuthTokens
{
    public const REFRESH_COOKIE = 'refresh_token';

    private const ACCESS_TTL_MIN = 60;

    private const REFRESH_TTL_MIN = 60 * 24 * 30; // 30 days

    public function __construct(private readonly CookieJar $cookie) {}

    public function issueAccess(User $user): string
    {
        return $user->createToken('access', ['*'], now()->addMinutes(self::ACCESS_TTL_MIN))
            ->plainTextToken;
    }

    /** Creates a refresh token row and returns the plaintext value for the cookie. */
    public function issueRefresh(User $user): string
    {
        $plain = Str::random(64);
        RefreshToken::create([
            'user_id' => $user->id,
            'token_hash' => hash('sha256', $plain),
            'expires_at' => now()->addMinutes(self::REFRESH_TTL_MIN),
        ]);

        return $plain;
    }

    /** Finds the active refresh token for a plaintext cookie value, or null. */
    public function findRefresh(?string $plain): ?RefreshToken
    {
        if (! $plain) {
            return null;
        }

        return RefreshToken::query()
            ->where('token_hash', hash('sha256', $plain))
            ->whereNull('revoked_at')
            ->where('expires_at', '>', now())
            ->first();
    }

    public function refreshCookie(string $plain): Cookie
    {
        return $this->cookie->make(
            self::REFRESH_COOKIE,
            $plain,
            self::REFRESH_TTL_MIN,
            '/',
            null,
            app()->environment('production'), // secure
            true,                              // httpOnly
            false,
            'lax',
        );
    }

    public function forgetCookie(): Cookie
    {
        return $this->cookie->forget(self::REFRESH_COOKIE);
    }
}
