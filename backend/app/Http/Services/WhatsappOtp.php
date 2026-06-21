<?php

namespace App\Http\Services;

use App\Jobs\WhatsAppJob;
use App\Models\Code;
use Carbon\Carbon;
use Exception;

/**
 * WhatsApp OTP service for password recovery — ported from the Eagle monolith
 * (app/Http/Services/WhatsappOtp.php).
 *
 * Generates a 6-digit code, persists it in the `codes` table keyed by phone, and
 * dispatches a WhatsAppJob to deliver it. Enforces the same abuse limits as Eagle:
 *   - at most 10 codes per phone per day
 *   - a 2-minute cooldown between consecutive sends
 *   - a code stays valid for 1 hour
 */
class WhatsappOtp
{
    /**
     * Generate + dispatch an OTP to the given phone.
     *
     * @throws Exception when the daily limit is hit or the cooldown is active.
     */
    public function sendOtpMessage(string $phone): void
    {
        $data = $this->getCodeInfo($phone);

        if (($data?->count ?? 0) >= 10) {
            throw new Exception(__('you-spent-all-chances'));
        }

        if (Carbon::createFromTimeString($data?->created_at ?? now()->copy()->subDay()->toDateTimeString())->addMinutes(2) > now()) {
            throw new Exception(__('wait-2-minutes'));
        }

        $otp = $this->generateOtp($phone);

        dispatch(new WhatsAppJob($phone, (string) $otp->code));
    }

    /**
     * Aggregate today's code activity for a phone: latest created_at + count.
     */
    public function getCodeInfo(string $phone)
    {
        return Code::query()
            ->selectRaw('phone, max(created_at) as created_at, count(code) as count')
            ->where('phone', $phone)
            ->whereDate('created_at', today())
            ->groupBy('phone')
            ->first();
    }

    public function generateOtp(string $phone): Code
    {
        $this->resetCodes($phone);

        $otp = new Code();
        $otp->phone = $phone;
        $otp->code = (string) rand(100000, 900000);
        $otp->save();

        return $otp;
    }

    /**
     * A code is valid if it exists for this phone and was created within the last hour.
     */
    public function isValidate(string $phone, string $code): bool
    {
        return Code::query()
            ->where('phone', $phone)
            ->where('code', $code)
            ->where('created_at', '>', Carbon::now()->subHour()->toDateTimeString())
            ->exists();
    }

    public function resetCodes(string $phone): int
    {
        return Code::query()->where('phone', $phone)->delete();
    }
}
