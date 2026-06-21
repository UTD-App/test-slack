<?php

namespace App\Facades;

use App\Services\Mail\EmailTemplateRegistry;
use App\Support\Mail\EmailTemplateType;
use Illuminate\Support\Facades\Facade;

/**
 * Catalogue of email-template types. Register a type once in a provider boot():
 *
 *   EmailTemplates::register('welcome', [
 *       'label'           => fn () => __('admin.email_tpl_welcome'),
 *       'description'     => fn () => __('admin.email_tpl_welcome_desc'),
 *       'placeholders'    => ['name' => 'admin.email_ph_name'],
 *       'default_subject' => fn (string $locale) => __('welcome-email-subject', [], $locale),
 *       'default_body'    => fn (string $locale) => \App\Models\EmailTemplate::renderBladeInLocale('emails.welcome', [], $locale),
 *   ]);
 *
 * Then send it anywhere:
 *   Mail::to($user->email)->send(new \App\Mail\TemplatedMail('welcome', ['name' => $user->name]));
 *
 * @method static void register(string $key, array $meta)
 * @method static bool has(string $key)
 * @method static EmailTemplateType|null get(string $key)
 * @method static array all()
 * @method static array keys()
 *
 * @see \App\Services\Mail\EmailTemplateRegistry
 */
class EmailTemplates extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return EmailTemplateRegistry::class;
    }
}
