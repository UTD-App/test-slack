<?php

namespace App\Http\Services;

use App\Mail\OtpCodeMail;
use App\Models\Code;
use Carbon\Carbon;
use Exception;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;

/**
 * Email OTP service for password recovery.
 *
 * Generates a 6-digit code, persists it in the `codes` table keyed by email, and
 * emails it. Abuse limits:
 *   - at most 10 codes per email per day
 *   - a 2-minute cooldown between consecutive sends
 *   - a code stays valid for OTP_TTL_MINUTES
 *   - at most MAX_VERIFY_ATTEMPTS wrong verifications per email before lockout
 */
class EmailOtp
{
    /** Minutes a generated code stays valid. */
    private const OTP_TTL_MINUTES = 10;

    /** Wrong verification attempts allowed per email before the code is locked out. */
    private const MAX_VERIFY_ATTEMPTS = 5;
    /**
     * Generate + email an OTP to the given address.
     *
     * @throws Exception when the daily limit is hit or the cooldown is active.
     */
    public function sendOtpMessage(string $email): void
    {
        $data = $this->getCodeInfo($email);

        if (($data?->count ?? 0) >= 10) {
            throw new Exception(__('you-spent-all-chances'));
        }

        if (Carbon::createFromTimeString($data?->created_at ?? now()->copy()->subDay()->toDateTimeString())->addMinutes(2) > now()) {
            throw new Exception(__('wait-2-minutes'));
        }

        $otp = $this->generateOtp($email);

        // Sent synchronously so delivery does not depend on a queue worker.
        Mail::to($email)->send(new OtpCodeMail((string) $otp->code));
    }

    /**
     * Aggregate today's code activity for an email: latest created_at + count.
     */
    public function getCodeInfo(string $email)
    {
        return Code::query()
            ->selectRaw('email, max(created_at) as created_at, count(code) as count')
            ->where('email', $email)
            ->whereDate('created_at', today())
            ->groupBy('email')
            ->first();
    }

    public function generateOtp(string $email): Code
    {
        $this->resetCodes($email);

        // CSPRNG over the full 6-digit space, zero-padded so 000123 stays 6 digits.
        $otp = new Code();
        $otp->email = $email;
        $otp->code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $otp->save();

        // A freshly issued code resets the brute-force counter for this email.
        RateLimiter::clear($this->attemptsKey($email));

        return $otp;
    }

    /**
     * A code is valid if it exists for this email and is still within its TTL.
     */
    public function isValidate(string $email, string $code): bool
    {
        return Code::query()
            ->where('email', $email)
            ->where('code', $code)
            ->where('created_at', '>', Carbon::now()->subMinutes(self::OTP_TTL_MINUTES)->toDateTimeString())
            ->exists();
    }

    /**
     * Validate a code with a per-email brute-force guard. Each wrong code counts
     * against MAX_VERIFY_ATTEMPTS (keyed on the email, so rotating IPs does not
     * help an attacker); a correct code clears the counter.
     *
     * @throws Exception when too many wrong attempts have been made.
     */
    public function attemptValidate(string $email, string $code): bool
    {
        $key = $this->attemptsKey($email);

        if (RateLimiter::tooManyAttempts($key, self::MAX_VERIFY_ATTEMPTS)) {
            throw new Exception(__('too-many-attempts'));
        }

        if ($this->isValidate($email, $code)) {
            RateLimiter::clear($key);

            return true;
        }

        RateLimiter::hit($key, self::OTP_TTL_MINUTES * 60);

        return false;
    }

    public function resetCodes(string $email): int
    {
        RateLimiter::clear($this->attemptsKey($email));

        return Code::query()->where('email', $email)->delete();
    }

    /** Cache key for the per-email wrong-attempt counter. */
    private function attemptsKey(string $email): string
    {
        return 'otp_verify:' . sha1(mb_strtolower($email));
    }
}
