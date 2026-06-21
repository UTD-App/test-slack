<?php

namespace App\Services\Mail;

use App\Support\Mail\EmailTemplateType;

/**
 * In-memory catalogue of every email-template TYPE the running app knows about.
 *
 * The Base registers core types (e.g. password_reset_otp) in
 * AppServiceProvider::boot(); each package registers its own types in its
 * provider boot() — so the platform stays modular and new emails appear in the
 * admin "Email Templates" page automatically.
 *
 * Resolved via the singleton bound in {@see \App\Providers\AppServiceProvider};
 * use the {@see \App\Facades\EmailTemplates} facade.
 */
class EmailTemplateRegistry
{
    /** @var array<string, EmailTemplateType> */
    protected array $types = [];

    /**
     * Register (or override) a type.
     *
     * @param  array<string,mixed>  $meta  label, description, placeholders, default_subject, default_body
     */
    public function register(string $key, array $meta): void
    {
        $this->types[$key] = EmailTemplateType::fromArray($key, $meta);
    }

    public function has(string $key): bool
    {
        return isset($this->types[$key]);
    }

    public function get(string $key): ?EmailTemplateType
    {
        return $this->types[$key] ?? null;
    }

    /** @return array<string, EmailTemplateType> */
    public function all(): array
    {
        return $this->types;
    }

    /** @return array<int, string> */
    public function keys(): array
    {
        return array_keys($this->types);
    }
}
