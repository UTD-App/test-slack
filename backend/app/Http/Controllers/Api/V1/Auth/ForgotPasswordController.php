<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Http\Services\EmailOtp;
use App\Models\User;
use Illuminate\Http\Request;

class ForgotPasswordController extends Controller
{
    // ──────────────────────────────────────────────────────────────────────────
    // Email-OTP recovery. send-otp → verify-code → reset-otp. A 6-digit code is
    // emailed to the address on the account (see EmailOtp + OtpCodeMail); the code
    // is never returned through the API.
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Step 1: email a 6-digit OTP to the address registered on an account.
     */
    public function sendOtp(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $exists = User::where('email', $request->email)->exists();
        if (!$exists) {
            return Common::apiResponse(false, __('user-not-found'), null, 422);
        }

        try {
            (new EmailOtp())->sendOtpMessage($request->email);
        } catch (\Exception $e) {
            // Daily-limit / cooldown / mail-transport errors bubble up here.
            return Common::apiResponse(false, $e->getMessage(), null, 422);
        }

        return Common::apiResponse(true, __('code-sent'));
    }

    /**
     * Step 2: check an OTP without consuming it (lets the UI advance to step 3).
     * Wrong codes are rate-limited per email (see EmailOtp::attemptValidate).
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string',
        ]);

        try {
            $valid = (new EmailOtp())->attemptValidate($request->email, $request->code);
        } catch (\Exception $e) {
            return Common::apiResponse(false, $e->getMessage(), null, 429);
        }

        if (!$valid) {
            return Common::apiResponse(false, __('invalid-code'), null, 422);
        }

        return Common::apiResponse(true, __('valid-code'));
    }

    /**
     * Step 3: verify the OTP again and set the new password, then clear codes.
     */
    public function resetWithOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string',
            'password' => 'required|string|min:6',
        ]);

        $otp = new EmailOtp();

        try {
            $valid = $otp->attemptValidate($request->email, $request->code);
        } catch (\Exception $e) {
            return Common::apiResponse(false, $e->getMessage(), null, 429);
        }

        if (!$valid) {
            return Common::apiResponse(false, __('invalid-code'), null, 422);
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return Common::apiResponse(false, __('user-not-found'), null, 422);
        }

        $user->password = $request->password; // auto-hashed by User::setPasswordAttribute
        $user->save();

        // Revoke every existing session so a thief who reset the password (or an
        // attacker already holding a stolen token) is logged out everywhere.
        if (method_exists($user, 'tokens')) {
            $user->tokens()->delete();
        }

        $otp->resetCodes($request->email);

        return Common::apiResponse(true, __('password-reset-successful'));
    }
}
