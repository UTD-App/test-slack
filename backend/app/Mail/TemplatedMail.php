<?php

namespace App\Mail;

use App\Models\EmailTemplate;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\App;

/**
 * Generic, data-driven mailable. Renders an admin-editable template (resolved by
 * key from the EmailTemplateRegistry / email_templates table) and substitutes
 * {{placeholders}} from $vars. Send any registered email with:
 *
 *   Mail::to($addr)->send(new TemplatedMail('password_reset_otp', ['code' => $code]));
 *
 * Falls back to an (almost) empty body only if the key is unknown AND has no
 * stored template — registered types always provide a default, so in practice
 * the template always renders.
 */
class TemplatedMail extends Mailable
{
    use Queueable, SerializesModels;

    /** @param array<string,mixed> $vars */
    public function __construct(public string $templateKey, public array $vars = [])
    {
    }

    public function build()
    {
        $rendered = EmailTemplate::render($this->templateKey, App::getLocale(), $this->vars);

        if ($rendered === null) {
            return $this->subject((string) config('app.name'))->html('<p></p>');
        }

        return $this->subject($rendered['subject'])->html($rendered['html']);
    }
}
