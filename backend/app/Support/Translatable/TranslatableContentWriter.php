<?php

namespace App\Support\Translatable;

use Illuminate\Database\Eloquent\Model;

/**
 * Writes localized values into a model's keyed-by-locale JSON attributes for one
 * locale, then saves. Shared by the "Content translations" page's row action and
 * its "AI-translate all missing" bulk action so both take the SAME write path
 * (and so it's testable without booting Livewire). Produces the identical JSON
 * shape the per-page editor writes.
 */
class TranslatableContentWriter
{
    /**
     * @param  array<int,string>     $fields  attribute names to write
     * @param  array<string,mixed>   $values  field => value (missing keys skipped)
     */
    public static function write(Model $model, array $fields, string $locale, array $values): void
    {
        foreach ($fields as $field) {
            if (! array_key_exists($field, $values)) {
                continue;
            }

            $map = $model->getAttribute($field);
            $map = is_array($map) ? $map : [];
            $map[$locale] = (string) $values[$field];

            $model->setAttribute($field, $map);
        }

        $model->save();
    }
}
