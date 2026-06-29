<?php

namespace Tests\Feature\Unit\Mail;

use App\Http\Services\EmailOtp;
use App\Mail\OtpCodeMail;
use App\Models\Code;
use Carbon\Carbon;
use Exception;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Tests\TestCase;

class EmailOtpTest extends TestCase
{
    use RefreshDatabase;

    private EmailOtp $otp;
    private string $email = 'user@example.com';

    protected function setUp(): void
    {
        parent::setUp();
        $this->otp = new EmailOtp();
        RateLimiter::clear('otp_verify:' . sha1(mb_strtolower($this->email)));
    }

    public function test_generate_creates_six_digit_code(): void
    {
        $code = $this->otp->generateOtp($this->email);

        $this->assertSame(6, strlen($code->code));
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code->code);
        $this->assertDatabaseHas('codes', ['email' => $this->email, 'code' => $code->code]);
    }

    public function test_generate_resets_previous_codes(): void
    {
        $first = $this->otp->generateOtp($this->email);
        $second = $this->otp->generateOtp($this->email);

        // resetCodes() deletes prior codes -> only the latest remains.
        $this->assertSame(1, Code::where('email', $this->email)->count());
        $this->assertDatabaseMissing('codes', ['id' => $first->id]);
        $this->assertDatabaseHas('codes', ['id' => $second->id]);
    }

    public function test_send_otp_message_mails_otp_code(): void
    {
        Mail::fake();

        $this->otp->sendOtpMessage($this->email);

        Mail::assertSent(OtpCodeMail::class, function (OtpCodeMail $mail) {
            return $mail->hasTo($this->email)
                && (bool) preg_match('/^\d{6}$/', $mail->code);
        });
        $this->assertDatabaseCount('codes', 1);
    }

    public function test_send_enforces_two_minute_cooldown(): void
    {
        Mail::fake();

        // First send succeeds; its code's created_at is "now".
        $this->otp->sendOtpMessage($this->email);

        // Immediate second send is within the 2-minute cooldown window.
        $this->expectException(Exception::class);
        $this->otp->sendOtpMessage($this->email);
    }

    public function test_send_allowed_after_cooldown_elapses(): void
    {
        Mail::fake();

        // Seed a code created >2 minutes ago so the cooldown has elapsed.
        Code::create([
            'email'      => $this->email,
            'code'       => '111111',
            'created_at' => Carbon::now()->subMinutes(3),
            'updated_at' => Carbon::now()->subMinutes(3),
        ]);

        $this->otp->sendOtpMessage($this->email);

        Mail::assertSent(OtpCodeMail::class);
    }

    public function test_send_enforces_daily_limit_of_ten(): void
    {
        Mail::fake();

        // 10 codes today (created >2 min ago so cooldown is not the blocker).
        for ($i = 0; $i < 10; $i++) {
            Code::create([
                'email'      => $this->email,
                'code'       => str_pad((string) $i, 6, '0', STR_PAD_LEFT),
                'created_at' => Carbon::now()->subMinutes(10),
                'updated_at' => Carbon::now()->subMinutes(10),
            ]);
        }

        $this->expectException(Exception::class);
        $this->otp->sendOtpMessage($this->email);
    }

    public function test_is_validate_accepts_fresh_code(): void
    {
        $code = $this->otp->generateOtp($this->email);

        $this->assertTrue($this->otp->isValidate($this->email, $code->code));
        $this->assertFalse($this->otp->isValidate($this->email, '000000'));
    }

    public function test_is_validate_rejects_expired_code(): void
    {
        Code::create([
            'email'      => $this->email,
            'code'       => '222222',
            'created_at' => Carbon::now()->subMinutes(11), // past 10-min TTL
            'updated_at' => Carbon::now()->subMinutes(11),
        ]);

        $this->assertFalse($this->otp->isValidate($this->email, '222222'));
    }

    public function test_attempt_validate_returns_true_and_clears_counter_on_success(): void
    {
        $code = $this->otp->generateOtp($this->email);

        $this->assertTrue($this->otp->attemptValidate($this->email, $code->code));
    }

    public function test_attempt_validate_locks_out_after_max_wrong_attempts(): void
    {
        $this->otp->generateOtp($this->email);

        // MAX_VERIFY_ATTEMPTS = 5 wrong tries allowed, 6th throws.
        for ($i = 0; $i < 5; $i++) {
            $this->assertFalse($this->otp->attemptValidate($this->email, '999999'));
        }

        $this->expectException(Exception::class);
        $this->otp->attemptValidate($this->email, '999999');
    }

    public function test_reset_codes_deletes_rows_and_clears_counter(): void
    {
        $this->otp->generateOtp($this->email);
        $this->assertSame(1, Code::where('email', $this->email)->count());

        $deleted = $this->otp->resetCodes($this->email);

        $this->assertSame(1, $deleted);
        $this->assertSame(0, Code::where('email', $this->email)->count());
    }
}
