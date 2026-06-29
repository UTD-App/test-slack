<?php

namespace Tests\Feature\Unit\Mail;

use App\Mail\OtpCodeMail;
use App\Mail\TemplatedMail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OtpCodeMailTest extends TestCase
{
    use RefreshDatabase;

    public function test_construct_stores_code_and_binds_template(): void
    {
        $mail = new OtpCodeMail('123456');

        $this->assertInstanceOf(TemplatedMail::class, $mail);
        $this->assertSame('123456', $mail->code);
        $this->assertSame('password_reset_otp', $mail->templateKey);
        $this->assertSame(['code' => '123456'], $mail->vars);
    }

    public function test_build_renders_registered_template_with_code(): void
    {
        // The 'password_reset_otp' type ships a default template, so the mailable
        // resolves a real subject/body and substitutes the {{code}} placeholder.
        $mail = new OtpCodeMail('654321');

        // render() runs build() and returns the final HTML string.
        $html = $mail->render();

        $this->assertNotEmpty($mail->subject);
        $this->assertStringContainsString('654321', $html);
    }
}
