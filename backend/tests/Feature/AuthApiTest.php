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
        $user = User::factory()->create(['password' => bcrypt('password')]);

        $this->postJson('/api/auth/login', [
            'email'    => $user->email,
            'password' => 'password',
        ])->assertStatus(200)->assertJsonStructure(['data' => ['token']]);
    }

    public function test_login_with_invalid_credentials_fails(): void
    {
        $this->postJson('/api/auth/login', [
            'email'    => 'wrong@example.com',
            'password' => 'wrongpass',
        ])->assertStatus(401);
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
