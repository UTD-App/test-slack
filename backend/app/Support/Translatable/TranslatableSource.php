<?php

namespace App\Support\Translatable;

use Closure;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * Describes one translatable dynamic-content source (e.g. content Pages) for the
 * per-language "Content translations" admin page. Registered in the
 * {@see \App\Services\TranslatableContentRegistry}. Style mirrors
 * {@see \App\Support\Mail\EmailTemplateType}.
 *
 * The model MUST use {@see \App\Models\Concerns\HasTranslations} and cast each
 * listed field to `array` (a {locale => value} map).
 */
class TranslatableSource
{
    /**
     * @param  array<string,bool>  $fields  attribute => isHtml
     */
    public function __construct(
        public readonly string $key,
        protected Closure $label,
        public readonly string $model,
        public readonly array $fields,
        protected Closure $itemLabel,
        protected ?Closure $editUrl = null,
        protected ?Closure $query = null,
    ) {}

    /**
     * @param  array<string,mixed>  $meta
     */
    public static function fromArray(string $key, array $meta): self
    {
        $model = $meta['model'] ?? null;
        if (! is_string($model) || $model === '') {
            throw new \InvalidArgumentException("Translatable content source [{$key}] requires a 'model'.");
        }

        return new self(
            key: $key,
            label: $meta['label'] ?? fn () => $key,
            model: $model,
            fields: $meta['fields'] ?? [],
            itemLabel: $meta['itemLabel'] ?? fn (Model $m) => (string) $m->getKey(),
            editUrl: $meta['editUrl'] ?? null,
            query: $meta['query'] ?? null,
        );
    }

    public function label(): string
    {
        return (string) ($this->label)();
    }

    public function itemLabel(Model $model): string
    {
        return (string) ($this->itemLabel)($model);
    }

    public function editUrl(Model $model): ?string
    {
        return $this->editUrl ? ($this->editUrl)($model) : null;
    }

    public function query(): Builder
    {
        return $this->query ? ($this->query)() : $this->model::query();
    }

    /** @return array<int,string> */
    public function fieldNames(): array
    {
        return array_keys($this->fields);
    }

    public function isHtml(string $field): bool
    {
        return (bool) ($this->fields[$field] ?? false);
    }
}
