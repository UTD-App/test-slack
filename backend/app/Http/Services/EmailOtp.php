<?php

namespace App\Http\Services;

use App\Mail\OtpCodeMail;
use App\Models\Code;
use Carbon\Carbon;
use Exception;
use Illuminate\Support\Facades\Mail;

/**
 * Email OTP service for password recovery.
 *
 * Generates a 6-digit code, persists it in the `codes` table keyed by email, and
 * emails it. Same abuse limits as the WhatsApp variant:
 *   - at most 10 codes per email per day
 *   - a 2-minute cooldown between consecutive sends
 *   - a code stays valid for 1 hour
 */
class EmailOtp
{
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

        $otp = new Code();
        $otp->email = $email;
        $otp->code = (string) rand(100000, 900000);
        $otp->save();

        return $otp;
    }

    /**
     * A code is valid if it exists for this email and was created within the last hour.
     */
    public function isValidate(string $email, string $code): bool
    {
        return Code::query()
            ->where('email', $email)
            ->where('code', $code)
            ->where('created_at', '>', Carbon::now()->subHour()->toDateTimeString())
            ->exists();
    }

    public function resetCodes(string $email): int
    {
        return Code::query()->where('email', $email)->delete();
    }
}
