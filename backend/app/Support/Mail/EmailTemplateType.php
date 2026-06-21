<?php

namespace App\Support\Mail;

use Closure;

/**
 * Immutable metadata for one email-template TYPE, registered once by the owning
 * package (or the Base for core types) via the EmailTemplateRegistry / the
 * {@see \App\Facades\EmailTemplates} facade.
 *
 * A "type" is an email the app can send (e.g. 'password_reset_otp'). It carries:
 *  - a translated label + description (admin UI),
 *  - the placeholders it supports ({{name}} => description translation key),
 *  - the DEFAULT subject + HTML body per-locale (shown until an admin overrides
 *    them, and used by "Restore default").
 *
 * The admin's edited copy lives in the `email_templates` table
 * ({@see \App\Models\EmailTemplate}).
 */
class EmailTemplateType
{
    /**
     * @param  array<string,string>     $placeholders   name => description (translation key or literal)
     * @param  Closure(string): string  $defaultSubject fn(locale): subject
     * @param  Closure(string): string  $defaultBody    fn(locale): html
     */
    public function __construct(
        public readonly string $key,
        public readonly Closure $label,
        public readonly Closure $description,
        public readonly array $placeholders,
        public readonly Closure $defaultSubject,
        public readonly Closure $defaultBody,
    ) {
    }

    /**
     * @param  array<string,mixed>  $meta  label, description, placeholders, default_subject, default_body
     */
    public static function fromArray(string $key, array $meta): self
    {
        return new self(
            key: $key,
            label: $meta['label'] ?? fn () => $key,
            description: $meta['description'] ?? fn () => '',
            placeholders: $meta['placeholders'] ?? [],
            defaultSubject: $meta['default_subject'] ?? fn (string $locale) => '',
            defaultBody: $meta['default_body'] ?? fn (string $locale) => '',
        );
    }

    public function label(): string
    {
        return (string) ($this->label)();
    }

    public function description(): string
    {
        return (string) ($this->description)();
    }

    public function defaultSubject(string $locale): string
    {
        return (string) ($this->defaultSubject)($locale);
    }

    public function defaultBody(string $locale): string
    {
        return (string) ($this->defaultBody)($locale);
    }
}
