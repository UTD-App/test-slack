<?php

namespace App\Models;

use App\Support\AppLanguages;
use Illuminate\Database\Eloquent\Model;

class Language extends Model
{
    protected $guarded = [];

    protected $casts = [
        'is_rtl'     => 'boolean',
        'is_active'  => 'boolean',
        'is_default' => 'boolean',
    ];

    /**
     * Enforce EXACTLY ONE default language and keep the cached language metadata
     * ({@see AppLanguages}) in sync. The default is the basis for all
     * translatable content (resolver fallback + content-create forms), so there
     * must always be one and only one. The query-builder updates below bypass
     * model events (no recursion).
     */
    protected static function booted(): void
    {
        static::saved(function (self $language): void {
            if ($language->is_default) {
                // Setting one default clears it from every other language, and a
                // default must be active.
                static::query()
                    ->where('id', '!=', $language->getKey())
                    ->where('is_default', true)
                    ->update(['is_default' => false]);

                if (! $language->is_active) {
                    static::query()->whereKey($language->getKey())->update(['is_active' => true]);
                }
            } elseif (! static::query()->where('is_default', true)->exists()) {
                // Never leave zero defaults — re-promote this one.
                static::query()->whereKey($language->getKey())->update(['is_default' => true]);
            }

            AppLanguages::flush();
        });

        static::deleted(fn () => AppLanguages::flush());
    }

    public function translations()
    {
        return $this->hasMany(Translation::class);
    }
}
