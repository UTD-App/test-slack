<?php

namespace Tests\Feature\Unit\Requests;

use App\Http\Requests\Api\V1\Auth\RegisterRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class RegisterRequestTest extends TestCase
{
    use RefreshDatabase;

    private function rules(): array
    {
        return (new RegisterRequest())->rules();
    }

    public function test_rules_require_email_password_and_unique(): void
    {
        $rules = $this->rules();

        $this->assertContains('required', $rules['email']);
        $this->assertContains('email', $rules['email']);
        $this->assertContains('unique:users,email', $rules['email']);
        $this->assertContains('required', $rules['password']);
        $this->assertContains('min:6', $rules['password']);
    }

    public function test_passes_with_valid_payload(): void
    {
        $v = Validator::make(
            ['email' => 'new@b.com', 'password' => 'secret1'],
            $this->rules()
        );

        $this->assertTrue($v->passes());
    }

    public function test_fails_with_short_password(): void
    {
        $v = Validator::make(
            ['email' => 'new@b.com', 'password' => '123'],
            $this->rules()
        );

        $this->assertTrue($v->fails());
        $this->assertArrayHasKey('password', $v->errors()->toArray());
    }

    public function test_fails_with_duplicate_email(): void
    {
        $existing = User::factory()->create();

        $v = Validator::make(
            ['email' => $existing->email, 'password' => 'secret1'],
            $this->rules()
        );

        $this->assertTrue($v->fails());
        $this->assertArrayHasKey('email', $v->errors()->toArray());
    }

    public function test_fails_with_invalid_iso_length(): void
    {
        // iso must be exactly 2 chars when present.
        $v = Validator::make(
            ['email' => 'new@b.com', 'password' => 'secret1', 'iso' => 'EGY'],
            $this->rules()
        );

        $this->assertTrue($v->fails());
        $this->assertArrayHasKey('iso', $v->errors()->toArray());
    }

    public function test_endpoint_returns_422_envelope_on_duplicate_email(): void
    {
        $existing = User::factory()->create();

        $this->postJson('/api/auth/register', [
            'email'    => $existing->email,
            'password' => 'secret1',
        ])->assertStatus(422)
            ->assertJsonPath('status', false)
            ->assertJsonStructure(['status', 'message', 'data']);
    }
}
