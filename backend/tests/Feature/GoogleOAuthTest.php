<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Socialite\Facades\Socialite;
use Laravel\Socialite\Two\User as SocialiteUser;
use Mockery;
use Tests\TestCase;

class GoogleOAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_active_google_user_receives_tokens_and_redirects_to_callback(): void
    {
        config(['services.google.client_id' => 'test', 'services.google.client_secret' => 'test']);
        User::create(['email' => 'active@example.com', 'password_hash' => Hash::make('unused-password'), 'full_name' => 'Active User', 'role' => 'member', 'is_active' => true, 'email_verified_at' => now()]);
        $this->mockGoogleUser('active@example.com', 'Active User');

        $response = $this->get('/api/v1/auth/google/callback');

        $response->assertRedirectContains('/auth/callback#accessToken=');
        $response->assertCookie('refresh_token');
    }

    public function test_new_google_user_is_created_pending_and_redirected_to_login(): void
    {
        config(['services.google.client_id' => 'test', 'services.google.client_secret' => 'test']);
        $this->mockGoogleUser('new@example.com', 'New User');

        $this->get('/api/v1/auth/google/callback')->assertRedirect(config('app.frontend_url').'/login?pending=1');

        $this->assertDatabaseHas('users', ['email' => 'new@example.com', 'is_active' => false]);
    }

    private function mockGoogleUser(string $email, string $name): void
    {
        $profile = (new SocialiteUser)->setRaw([])->map(['id' => 'google-id', 'email' => $email, 'name' => $name, 'avatar' => 'https://example.com/avatar.png']);
        $provider = Mockery::mock();
        $provider->shouldReceive('stateless')->once()->andReturnSelf();
        $provider->shouldReceive('user')->once()->andReturn($profile);
        Socialite::shouldReceive('driver')->once()->with('google')->andReturn($provider);
    }
}
