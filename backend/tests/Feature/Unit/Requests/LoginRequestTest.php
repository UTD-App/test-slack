<?php

namespace Tests\Feature\Unit\Requests;

use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class LoginRequestTest extends TestCase
{
    use RefreshDatabase;

    private function rules(): array
    {
        return (new LoginRequest())->rules();
    }

    public function test_rules_require_email_and_password(): void
    {
        $rules = $this->rules();

        $this->assertContains('required', $rules['email']);
        $this->assertContains('email', $rules['email']);
        $this->assertContains('required', $rules['password']);
    }

    public function test_passes_with_valid_payload(): void
    {
        $v = Validator::make(
            ['email' => 'a@b.com', 'password' => 'secret'],
            $this->rules()
        );

        $this->assertTrue($v->passes());
    }

    public function test_fails_without_email(): void
    {
        $v = Validator::make(['password' => 'secret'], $this->rules());

        $this->assertTrue($v->fails());
        $this->assertArrayHasKey('email', $v->errors()->toArray());
    }

    public function test_fails_with_malformed_email(): void
    {
        $v = Validator::make(
            ['email' => 'not-an-email', 'password' => 'secret'],
            $this->rules()
        );

        $this->assertTrue($v->fails());
        $this->assertArrayHasKey('email', $v->errors()->toArray());
    }

    public function test_fails_without_password(): void
    {
        $v = Validator::make(['email' => 'a@b.com'], $this->rules());

        $this->assertTrue($v->fails());
        $this->assertArrayHasKey('password', $v->errors()->toArray());
    }

    public function test_endpoint_returns_422_envelope_on_validation_failure(): void
    {
        // failedValidation throws Common::apiResponse(status=false, ..., 422).
        $this->postJson('/api/auth/login', ['email' => 'bad'])
            ->assertStatus(422)
            ->assertJsonPath('status', false)
            ->assertJsonStructure(['status', 'message', 'data']);
    }

    public function test_endpoint_with_valid_credentials_passes_validation(): void
    {
        $user = User::factory()->create();

        $this->postJson('/api/auth/login', [
            'email'    => $user->email,
            'password' => 'password',
        ])->assertStatus(200)->assertJsonPath('status', true);
    }
}
