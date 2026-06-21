<?php

namespace App\Mail;

/**
 * Password-recovery OTP email. A thin wrapper over {@see TemplatedMail} bound to
 * the 'password_reset_otp' template, which is admin-editable in the dashboard
 * (Email Templates). Kept as its own class so existing call sites
 * (EmailOtp::sendOtpMessage) and tests (Mail::assertSent(OtpCodeMail::class))
 * keep working unchanged.
 *
 * The {{code}} placeholder in the template is replaced with the 6-digit code.
 */
class OtpCodeMail extends TemplatedMail
{
    public function __construct(public string $code)
    {
        parent::__construct('password_reset_otp', ['code' => $code]);
    }
}
