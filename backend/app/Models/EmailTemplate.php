<?php

namespace App\Models;

use App\Facades\EmailTemplates;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\View;

/**
 * The admin-editable copy of an email template, keyed by `key` (matching a type
 * registered in the EmailTemplateRegistry). `subject` and `body` are localized
 * maps ({en, ar, ...}); a missing locale falls back to the registered type's
 * shipped default (see render()). Edited from the admin "Email Templates"
 * resource and sent via {@see \App\Mail\TemplatedMail}.
 */
class EmailTemplate extends Model
{
    protected $table = 'email_templates';

    protected $fillable = ['key', 'subject', 'body'];

    protected $casts = [
        'subject' => 'array',
        'body'    => 'array',
    ];

    /**
     * Resolve the subject + HTML for a template key in a locale, with all
     * {{placeholders}} substituted. Returns null when there is nothing to render
     * (no stored body AND no registered default) so the caller can fall back.
     *
     * @param  array<string,mixed>  $vars
     * @return array{subject: string, html: string}|null
     */
    public static function render(string $key, ?string $locale = null, array $vars = []): ?array
    {
        $locale = $locale ?: App::getLocale();
        $type   = EmailTemplates::get($key);
        $row    = static::query()->where('key', $key)->first();

        $subject = (is_array($row?->subject)) ? ($row->subject[$locale] ?? null) : null;
        $body    = (is_array($row?->body)) ? ($row->body[$locale] ?? null) : null;

        if (($subject === null || $subject === '') && $type) {
            $subject = $type->defaultSubject($locale);
        }
        if (($body === null || $body === '') && $type) {
            $body = $type->defaultBody($locale);
        }

        if ($body === null || $body === '') {
            return null;
        }

        $vars = array_merge([
            'app_name' => config('app.name'),
            'year'     => date('Y'),
        ], $vars);

        return [
            'subject' => static::applyVars((string) $subject, $vars),
            'html'    => static::applyVars((string) $body, $vars),
        ];
    }

    /**
     * Substitute {{ placeholder }} tokens. Admin content is NEVER evaluated as
     * Blade/PHP — only literal token replacement — so a template can't run code.
     *
     * @param  array<string,mixed>  $vars
     */
    public static function applyVars(string $text, array $vars): string
    {
        // Normalize "{{ name }}" / "{{name}}" to a single canonical "{{name}}".
        $text = preg_replace('/\{\{\s*([\w.]+)\s*\}\}/', '{{$1}}', $text) ?? $text;

        $map = [];
        foreach ($vars as $name => $value) {
            $map['{{' . $name . '}}'] = (string) $value;
        }

        return strtr($text, $map);
    }

    /**
     * Render a Blade view under a specific locale (then restore). Lets registered
     * types derive their default HTML from a shipped blade so the design lives in
     * ONE place.
     *
     * @param  array<string,mixed>  $data
     */
    public static function renderBladeInLocale(string $view, array $data, string $locale): string
    {
        $previous = App::getLocale();
        App::setLocale($locale);

        try {
            return View::make($view, $data)->render();
        } finally {
            App::setLocale($previous);
        }
    }

    /**
     * Ensure a DB row exists for every registered type, pre-filled with that
     * type's default subject/body for the edited locales (en, ar) so the admin
     * always opens the *current* template. firstOrCreate → never clobbers edits.
     */
    public static function ensureRegisteredRows(): void
    {
        foreach (EmailTemplates::all() as $key => $type) {
            static::firstOrCreate(['key' => $key], static::defaultAttributes($type));
        }
    }

    /** Reset this row's subject/body back to its registered type defaults. */
    public function restoreDefaults(): void
    {
        $type = EmailTemplates::get($this->key);
        if (! $type) {
            return;
        }

        $this->update(static::defaultAttributes($type));
    }

    /**
     * The default (en, ar) subject/body attributes for a type.
     *
     * @return array{subject: array<string,string>, body: array<string,string>}
     */
    protected static function defaultAttributes(\App\Support\Mail\EmailTemplateType $type): array
    {
        return [
            'subject' => [
                'en' => $type->defaultSubject('en'),
                'ar' => $type->defaultSubject('ar'),
            ],
            'body' => [
                'en' => $type->defaultBody('en'),
                'ar' => $type->defaultBody('ar'),
            ],
        ];
    }
}
