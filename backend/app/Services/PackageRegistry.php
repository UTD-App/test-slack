<?php

namespace App\Services;

use App\Models\Package;
use Illuminate\Support\Facades\Cache;

/**
 * In-memory registry of packages that self-registered this worker boot,
 * plus helpers to read/sync the persisted `packages` table.
 *
 * Octane-safe: in-memory state is append-only and keyed by slug; DB writes
 * happen only in syncToDatabase() (called by `utd:sync-packages`), never per request.
 *
 * Enabled semantics: a package is enabled unless its row exists AND enabled=false.
 * A freshly dropped-in module (no row yet, before first sync) is treated as enabled.
 */
class PackageRegistry
{
    /** @var array<string, array> slug => manifest */
    protected array $manifests = [];

    /**
     * Record a package manifest in memory (called from a module ServiceProvider boot).
     *
     * @param array{slug:string, name?:string, version?:string, is_core?:bool, dependencies?:array} $manifest
     */
    public function register(array $manifest): void
    {
        if (empty($manifest['slug'])) {
            return;
        }
        $this->manifests[$manifest['slug']] = $manifest;
    }

    /** @return array<string, array> */
    public function all(): array
    {
        return $this->manifests;
    }

    /**
     * Persist every registered manifest to the `packages` table.
     * Preserves the admin-controlled `enabled` / `order` columns on existing rows.
     */
    public function syncToDatabase(): int
    {
        $count = 0;
        foreach ($this->manifests as $slug => $manifest) {
            $package = Package::firstOrNew(['slug' => $slug]);

            $package->fill([
                'name'         => $manifest['name'] ?? ucwords(str_replace(['-', '_'], ' ', $slug)),
                'version'      => $manifest['version'] ?? '1.0.0',
                'is_core'      => (bool) ($manifest['is_core'] ?? false),
                'dependencies' => $manifest['dependencies'] ?? [],
                'meta'         => $manifest['meta'] ?? null,
                // `enabled` and `order` are owned by the admin and never overwritten here;
                // new rows fall back to the column defaults (enabled=true, order=0).
            ]);

            // Stamp install time only on first insert — never clobber it on re-sync.
            if (! $package->exists) {
                $package->installed_at = now();
            }

            $package->save();
            $count++;
        }

        $this->forgetCache();

        return $count;
    }

    /**
     * Whether a package is enabled. Absent row => enabled (pre-sync modules work).
     */
    public function isEnabled(string $slug): bool
    {
        if ($slug === 'base') {
            return true;
        }

        return ! in_array($slug, $this->disabledSlugs(), true);
    }

    /**
     * Slugs of existing, enabled package rows (+ always 'base').
     * Used to filter menu payloads / Filament discovery to live packages.
     *
     * @return string[]
     */
    public function enabledSlugs(): array
    {
        return Cache::remember('packages_enabled_slugs', 3600, function () {
            try {
                $enabled = Package::where('enabled', true)->pluck('slug')->all();
            } catch (\Throwable) {
                $enabled = []; // table not migrated yet
            }

            return collect($enabled)->push('base')->unique()->values()->all();
        });
    }

    /**
     * Slugs explicitly disabled by the admin.
     *
     * @return string[]
     */
    public function disabledSlugs(): array
    {
        return Cache::remember('packages_disabled_slugs', 3600, function () {
            try {
                return Package::where('enabled', false)->pluck('slug')->all();
            } catch (\Throwable) {
                return [];
            }
        });
    }

    public function forgetCache(): void
    {
        Cache::forget('packages_enabled_slugs');
        Cache::forget('packages_disabled_slugs');
    }
}
