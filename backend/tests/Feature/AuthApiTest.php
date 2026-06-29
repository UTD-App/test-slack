<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_check_returns_ok(): void
    {
        $this->get('/api/health')->assertStatus(200);
    }

    public function test_login_with_valid_credentials(): void
    {
        // UserFactory sets password => 'password' (hashed once by the model mutator).
        $user = User::factory()->create();

        $this->postJson('/api/auth/login', [
            'email'    => $user->email,
            'password' => 'password',
        ])->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['data' => ['auth_token']]);
    }

    public function test_login_with_invalid_credentials_fails(): void
    {
        // The API returns the standard 422 envelope (status:false) on auth failure.
        $this->postJson('/api/auth/login', [
            'email'    => 'wrong@example.com',
            'password' => 'wrongpass',
        ])->assertStatus(422)->assertJsonPath('status', false);
    }

    public function test_authenticated_user_can_get_own_data(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/my-data')
            ->assertStatus(200)
            ->assertJsonPath('data.email', $user->email);
    }

    public function test_unauthenticated_request_to_protected_route_fails(): void
    {
        $this->getJson('/api/my-data')->assertStatus(401);
    }
}
