<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Http\Services\EmailOtp;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ForgotPasswordController extends Controller
{
    public function sendResetToken(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return Common::apiResponse(false, __('user-not-found'), null, 422);
        }

        $token = Str::random(64);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $request->email],
            ['token' => $token, 'created_at' => now()],
        );

        return Common::apiResponse(true, 'reset-token-generated', ['token' => $token]);
    }

    public function reset(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
            'password' => 'required|string|min:6',
        ]);

        $record = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->where('token', $request->token)
            ->where('created_at', '>', now()->subHour())
            ->first();

        if (!$record) {
            return Common::apiResponse(false, __('invalid-or-expired-token'), null, 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return Common::apiResponse(false, __('user-not-found'), null, 422);
        }

        $user->password = $request->password;
        $user->save();

        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return Common::apiResponse(true, 'password-reset-successful');
    }

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
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'code' => 'required|string',
        ]);

        if (!(new EmailOtp())->isValidate($request->email, $request->code)) {
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
        if (!$otp->isValidate($request->email, $request->code)) {
            return Common::apiResponse(false, __('invalid-code'), null, 422);
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return Common::apiResponse(false, __('user-not-found'), null, 422);
        }

        $user->password = $request->password; // auto-hashed by User::setPasswordAttribute
        $user->save();

        $otp->resetCodes($request->email);

        return Common::apiResponse(true, __('password-reset-successful'));
    }
}
