<?php

namespace App\Providers;

use Composer\Autoload\ClassLoader;
use Illuminate\Support\ServiceProvider;

/**
 * Generic package discovery — prepares the base to RECEIVE any package.
 *
 * Each assembled package lives self-contained under backend/packages/<name>/ and
 * ships its OWN composer.json (in its own repo) declaring its PSR-4 namespace(s)
 * and its Laravel service provider(s) under extra.laravel.providers.
 *
 * The base scans packages/*, reads each composer.json, registers the package's
 * PSR-4 at runtime, then registers its provider(s). The base never names a
 * specific package — no per-package entry in the base composer.json or
 * config/app.php. This mirrors flutter/packages/<name>/ and keeps packages
 * isolated, drop-in, and removable.
 *
 * Enable/disable gating happens inside the package provider
 * (BaseModuleServiceProvider::boot checks PackageRegistry::isEnabled) — a
 * disabled package still registers its manifest but loads no routes/migrations.
 */
class PackageServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $dir = base_path('packages');

        if (! is_dir($dir)) {
            return;
        }

        /** @var ClassLoader $loader */
        $loader = require base_path('vendor/autoload.php');

        foreach (glob($dir . '/*', GLOB_ONLYDIR) ?: [] as $packagePath) {
            $composerFile = $packagePath . '/composer.json';

            if (! is_file($composerFile)) {
                continue;
            }

            $manifest = json_decode((string) file_get_contents($composerFile), true);

            if (! is_array($manifest)) {
                continue;
            }

            // 1) Register the package's PSR-4 autoload at runtime (no base composer entry needed).
            foreach (($manifest['autoload']['psr-4'] ?? []) as $namespace => $relative) {
                $absolute = array_map(
                    fn ($p) => $packagePath . '/' . trim($p, '/'),
                    (array) $relative,
                );
                $loader->addPsr4($namespace, $absolute);
            }

            // 2) Register the package's Laravel service provider(s).
            foreach (($manifest['extra']['laravel']['providers'] ?? []) as $providerClass) {
                if (class_exists($providerClass)) {
                    $this->app->register($providerClass);
                }
            }
        }
    }
}
