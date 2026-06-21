<?php

namespace App\Services;

use App\Support\Translatable\TranslatableSource;

/**
 * In-memory catalogue of translatable dynamic-content sources. The base registers
 * `pages`; packages register their own in their provider boot() — each appears as
 * a tab on every language's "Content translations" page automatically.
 *
 * Style mirrors {@see \App\Services\Mail\EmailTemplateRegistry}. Access via the
 * {@see \App\Facades\TranslatableContent} facade or app(self::class).
 */
class TranslatableContentRegistry
{
    /** @var array<string,TranslatableSource> */
    private array $sources = [];

    /**
     * @param  array<string,mixed>  $meta  label, model, fields, itemLabel, editUrl?, query?
     */
    public function register(string $key, array $meta): void
    {
        $this->sources[$key] = TranslatableSource::fromArray($key, $meta);
    }

    public function has(string $key): bool
    {
        return isset($this->sources[$key]);
    }

    public function get(string $key): ?TranslatableSource
    {
        return $this->sources[$key] ?? null;
    }

    /** @return array<string,TranslatableSource> */
    public function all(): array
    {
        return $this->sources;
    }

    /** @return array<int,string> */
    public function keys(): array
    {
        return array_keys($this->sources);
    }
}
