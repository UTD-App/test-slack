<?php

namespace App\Models\Concerns;

use App\Support\Translatable;

/**
 * Makes a model's JSON "keyed-by-locale" attributes (cast to `array`) resolve to
 * a single localized string with fallback. Add `use HasTranslations;` to any
 * model whose attribute is stored as {"en":"...","fr":"..."} and cast to array:
 *
 *   $page->tr('title')         // resolved for the current app locale
 *   $page->tr('title', 'fr')   // resolved for a specific locale
 *   $page->trMap('title')      // the raw locale => value map (for admin forms)
 *
 * Resolution + fallback live in {@see \App\Support\Translatable}.
 */
trait HasTranslations
{
    public function tr(string $attribute, ?string $locale = null): string
    {
        $value = $this->getAttribute($attribute);

        return Translatable::resolveOr(is_array($value) ? $value : null, $locale, '');
    }

    /** @return array<string,string> */
    public function trMap(string $attribute): array
    {
        $value = $this->getAttribute($attribute);

        return is_array($value) ? array_map(static fn ($v) => (string) $v, $value) : [];
    }
}
