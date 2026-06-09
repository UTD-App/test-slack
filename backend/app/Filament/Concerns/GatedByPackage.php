<?php

namespace App\Filament\Concerns;

use App\Services\PackageRegistry;
use Illuminate\Support\Str;

/**
 * Lets a Filament Resource/Page declare the package it belongs to, so the screen
 * disappears the instant that package is disabled in admin/packages.
 *
 * Slug resolution order:
 *   1. explicit `protected static ?string $packageSlug` — for standalone
 *      composer packages (e.g. Utd\Moment → 'moment').
 *   2. derived from a `Modules\<Name>\...` namespace — legacy nwidart modules.
 *   3. null → first-party App\ screen, always available.
 *
 * Evaluated per request (cheap), so the *disable* path needs no Octane reload.
 * The *enable* path still needs a worker reboot (Filament discovery runs at boot).
 *
 * The using class declares the slug itself:
 *   protected static ?string $packageSlug = 'moment';
 * (The trait does NOT declare the property — that would clash with a class that
 * redeclares it with a different default during trait composition.)
 */
trait GatedByPackage
{
    protected static function resolvePackageSlug(): ?string
    {
        if (property_exists(static::class, 'packageSlug') && static::$packageSlug !== null) {
            return static::$packageSlug;
        }

        if (str_starts_with(static::class, 'Modules\\')) {
            $name = explode('\\', static::class)[1] ?? null;

            return $name ? Str::kebab($name) : null;
        }

        return null;
    }

    /** True when this screen's package is enabled (or it is core/first-party). */
    protected static function packageIsEnabled(): bool
    {
        $slug = static::resolvePackageSlug();

        return $slug === null || app(PackageRegistry::class)->isEnabled($slug);
    }
}
