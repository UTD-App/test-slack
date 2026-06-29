<?php

namespace Tests\Feature\Coverage;

use App\Models\Code;
use App\Models\Country;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * Endpoint coverage — the public + authenticated auth surface that had no test:
 *   POST /auth/register, POST /auth/login (correct shape), POST /check-email,
 *   POST /auth/logout, POST /account/delete, GET /auth/all-countries, GET /roles,
 *   and the email-OTP recovery flow (send-otp / verify-code / reset-otp).
 *
 * NOTE: User::setPasswordAttribute always bcrypts, so the factory's
 * `password => 'password'` is stored hashed. Tests log in with the plaintext
 * 'password' and must NOT pre-hash it (doing so double-hashes — see FINDINGS).
 */
class AuthEndpointsTest extends TestCase
{
    use RefreshDatabase;

    private function auth(User $user): static
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('test')->plainTextToken);
    }

    // ── register ───────────────────────────────────────────────────────────
    public function test_register_creates_user_and_returns_token(): void
    {
        $res = $this->postJson('/api/auth/register', [
            'email'    => 'newbie@example.com',
            'password' => 'secret123',
            'uuid'     => 'uuid-123',
        ]);

        $res->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['data' => ['id', 'is_first', 'auth_token']]);

        $this->assertDatabaseHas('users', ['email' => 'newbie@example.com']);
    }

    public function test_register_rejects_duplicate_email(): void
    {
        User::factory()->create(['email' => 'dupe@example.com']);

        $this->postJson('/api/auth/register', [
            'email'    => 'dupe@example.com',
            'password' => 'secret123',
        ])->assertStatus(422)->assertJsonPath('status', false);
    }

    public function test_register_rejects_short_password(): void
    {
        $this->postJson('/api/auth/register', [
            'email'    => 'shortpw@example.com',
            'password' => '123',
        ])->assertStatus(422);
    }

    // ── login (correct contract: returns data.auth_token, envelope key = status) ─
    public function test_login_with_valid_credentials_returns_auth_token(): void
    {
        $user = User::factory()->create(); // factory password = 'password' (auto-hashed)

        $this->postJson('/api/auth/login', [
            'email'    => $user->email,
            'password' => 'password',
        ])->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['data' => ['id', 'auth_token']]);
    }

    public function test_login_missing_email_is_422(): void
    {
        $this->postJson('/api/auth/login', ['password' => 'password'])
            ->assertStatus(422);
    }

    // ── check-email ─────────────────────────────────────────────────────────
    public function test_check_email_reports_existence(): void
    {
        User::factory()->create(['email' => 'known@example.com']);

        $this->postJson('/api/check-email', ['email' => 'known@example.com'])
            ->assertStatus(200)->assertJsonPath('data.exists', true);

        $this->postJson('/api/check-email', ['email' => 'unknown@example.com'])
            ->assertStatus(200)->assertJsonPath('data.exists', false);
    }

    public function test_check_email_requires_email(): void
    {
        $this->postJson('/api/check-email', [])->assertStatus(422);
    }

    // ── logout ──────────────────────────────────────────────────────────────
    public function test_logout_revokes_current_token(): void
    {
        $user  = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/auth/logout')
            ->assertStatus(200)->assertJsonPath('status', true);

        // Token is gone → the same bearer now fails.
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/my-data')
            ->assertStatus(401);
    }

    // ── account/delete ────────────────────────────────────────────────────────
    public function test_delete_account_soft_deletes_and_revokes_tokens(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->postJson('/api/account/delete')
            ->assertStatus(200)->assertJsonPath('status', true);

        $this->assertSoftDeleted('users', ['id' => $user->id]);
    }

    // ── all-countries (public) ─────────────────────────────────────────────────
    public function test_all_countries_is_public_and_lists_countries(): void
    {
        Country::create(['name' => 'مصر', 'e_name' => 'Egypt', 'iso' => 'EG', 'flag' => 'eg.png']);

        $this->getJson('/api/auth/all-countries')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonFragment(['e_name' => 'Egypt']);
    }

    // ── roles (authed) ─────────────────────────────────────────────────────────
    public function test_roles_endpoint_returns_array(): void
    {
        $user = User::factory()->create();

        $this->auth($user)->getJson('/api/roles')
            ->assertStatus(200)
            ->assertJsonPath('status', true);
    }

    public function test_roles_requires_auth(): void
    {
        $this->getJson('/api/roles')->assertStatus(401);
    }

    // ── forgot-password: email OTP flow ────────────────────────────────────────
    public function test_send_otp_unknown_email_is_422(): void
    {
        $this->postJson('/api/auth/forgot-password/send-otp', ['email' => 'nobody@example.com'])
            ->assertStatus(422)->assertJsonPath('status', false);
    }

    public function test_send_otp_known_email_sends_mail(): void
    {
        Mail::fake();
        $user = User::factory()->create(['email' => 'reset@example.com']);

        $this->postJson('/api/auth/forgot-password/send-otp', ['email' => 'reset@example.com'])
            ->assertStatus(200)->assertJsonPath('status', true);

        $this->assertDatabaseHas('codes', ['email' => 'reset@example.com']);
    }

    public function test_verify_code_rejects_wrong_code(): void
    {
        Mail::fake();
        User::factory()->create(['email' => 'reset2@example.com']);
        $this->postJson('/api/auth/forgot-password/send-otp', ['email' => 'reset2@example.com'])->assertStatus(200);

        $this->postJson('/api/auth/forgot-password/verify-code', [
            'email' => 'reset2@example.com',
            'code'  => '000000-wrong',
        ])->assertStatus(422);
    }

    public function test_reset_with_otp_sets_new_password_end_to_end(): void
    {
        Mail::fake();
        $user = User::factory()->create(['email' => 'reset3@example.com']);
        $this->postJson('/api/auth/forgot-password/send-otp', ['email' => 'reset3@example.com'])->assertStatus(200);

        // Read the real code straight from the DB (it is never returned by the API).
        $code = Code::where('email', 'reset3@example.com')->latest('id')->first()->code;

        $this->postJson('/api/auth/forgot-password/reset-otp', [
            'email'    => 'reset3@example.com',
            'code'     => $code,
            'password' => 'brand-new-pass',
        ])->assertStatus(200)->assertJsonPath('status', true);

        // New password works for login.
        $this->postJson('/api/auth/login', [
            'email'    => 'reset3@example.com',
            'password' => 'brand-new-pass',
        ])->assertStatus(200);
    }
}
