<?php

namespace App\Modules;

use App\Contracts\MenuContributor;
use App\Contracts\UserDataContributor;
use App\Services\MenuService;
use App\Services\PackageRegistry;
use App\Services\UserDataService;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;
use ReflectionClass;

/**
 * Base class every package ServiceProvider extends. A package placed in
 * backend/packages/<name>/ with its provider at src/Providers/<Name>ServiceProvider.php
 * self-wires its routes, migrations, translations and capability registrations —
 * with NO edits to the base. The base discovers and registers the provider via
 * PackageServiceProvider (reading the package's own composer.json).
 *
 * Paths are resolved relative to the concrete provider's own file location (not a
 * hardcoded Modules/ dir), so the package is location-agnostic.
 *
 * DB writes (package row, role/setting/menu defaults) happen in `utd:sync-packages`,
 * not here, so this is safe to run on every worker boot under Octane.
 */
abstract class BaseModuleServiceProvider extends ServiceProvider
{
    /** Package slug, e.g. 'audio-room'. Must match packages.slug / translation group. */
    abstract public function packageSlug(): string;

    /** Studly package name, e.g. 'AudioRoom'. Derived from the slug by default. */
    public function moduleName(): string
    {
        return Str::studly(str_replace('-', '_', $this->packageSlug()));
    }

    /**
     * Absolute path to the package root (backend/packages/<name>).
     * Resolved from the concrete provider at <root>/src/Providers/<X>ServiceProvider.php.
     * Override if your package uses a different provider depth.
     */
    public function packagePath(): string
    {
        return dirname((new ReflectionClass(static::class))->getFileName(), 3);
    }

    /**
     * @return array{name?:string, version?:string, is_core?:bool, dependencies?:array, meta?:array}
     */
    public function packageManifest(): array
    {
        return [];
    }

    /** @return array<int, string|array{key:string, display_name?:string}> */
    public function roles(): array
    {
        return [];
    }

    /** @return array<int, array{key:string, type?:string, default?:mixed, label_key?:string}> */
    public function settings(): array
    {
        return [];
    }

    public function register(): void
    {
        // Record the manifest (incl. role/setting definitions) in memory as early as
        // possible so `utd:sync-packages` and enabled checks can see it.
        app(PackageRegistry::class)->register(array_merge(
            ['slug' => $this->packageSlug()],
            $this->packageManifest(),
            ['roles' => $this->roles(), 'settings' => $this->settings()],
        ));
    }

    public function boot(): void
    {
        if (! app(PackageRegistry::class)->isEnabled($this->packageSlug())) {
            return;
        }

        $dir = $this->packagePath();

        if (is_file($dir . '/routes/api.php')) {
            Route::prefix('api')
                ->middleware(['api', 'localization'])
                ->group($dir . '/routes/api.php');
        }

        if (is_dir($dir . '/database/migrations')) {
            $this->loadMigrationsFrom($dir . '/database/migrations');
        }

        if (is_dir($dir . '/Resources/lang')) {
            $this->loadTranslationsFrom($dir . '/Resources/lang', $this->packageSlug());
        }

        $this->registerCapabilities();
    }

    /**
     * Register in-memory capability contributors (cheap, no DB). The package
     * ServiceProvider itself may implement MenuContributor / UserDataContributor.
     */
    protected function registerCapabilities(): void
    {
        if ($this instanceof MenuContributor) {
            app(MenuService::class)->register($this);
        }

        if ($this instanceof UserDataContributor) {
            app(UserDataService::class)->register($this);
        }
    }
}
