<?php

namespace App\Support\Translatable;

/**
 * Form <-> JSON glue for editing ONLY the default-language value of translatable
 * attributes (the clean page editor). Translations for other languages are
 * managed in the per-language "Content translations" page; this MUST preserve
 * them when the admin saves the default content (never wipe other locales).
 */
class DefaultLocaleForm
{
    /**
     * Keyed-locale maps → `{name}_default` form fields.
     *
     * @param  array<string,mixed>  $data
     * @param  array<int,string>    $names
     * @return array<string,mixed>
     */
    public static function toForm(array $data, array $names, string $default): array
    {
        foreach ($names as $name) {
            $map = is_array($data[$name] ?? null) ? $data[$name] : [];
            $data["{$name}_default"] = (string) ($map[$default] ?? '');
            unset($data[$name]);
        }

        return $data;
    }

    /**
     * `{name}_default` form fields → keyed-locale maps, MERGING into the existing
     * map so every other locale's translation is preserved.
     *
     * @param  array<string,mixed>        $data
     * @param  array<int,string>          $names
     * @param  array<string,array|null>   $existing  name => current locale map (empty on create)
     * @return array<string,mixed>
     */
    public static function toModel(array $data, array $names, string $default, array $existing = []): array
    {
        foreach ($names as $name) {
            $map = is_array($existing[$name] ?? null) ? $existing[$name] : [];
            $map[$default] = (string) ($data["{$name}_default"] ?? '');
            $data[$name] = $map;
            unset($data["{$name}_default"]);
        }

        return $data;
    }
}
