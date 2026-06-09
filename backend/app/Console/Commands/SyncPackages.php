<?php

namespace App\Console\Commands;

use App\Models\Package;
use App\Services\MenuService;
use App\Services\PackageRegistry;
use App\Services\RoleService;
use App\Services\SettingService;
use Illuminate\Console\Command;

/**
 * Persists every self-registered module's defaults to the database:
 * package rows, roles, settings and menu items. Idempotent — run after
 * dropping in / updating a module, or on deploy.
 */
class SyncPackages extends Command
{
    protected $signature = 'utd:sync-packages';

    protected $description = 'Sync installed packages (rows, roles, settings, menu items) into the database';

    public function handle(
        PackageRegistry $packages,
        RoleService $roles,
        SettingService $settings,
        MenuService $menu,
    ): int {
        // Ensure the base (core) package row exists.
        Package::firstOrCreate(
            ['slug' => 'base'],
            ['name' => 'Base Project', 'version' => '1.0.0', 'is_core' => true, 'installed_at' => now()],
        );

        // 1) Persist package rows (preserves admin-owned enabled/order).
        $synced = $packages->syncToDatabase();
        $this->info("Packages synced: {$synced}");

        // 2) Flush each module's role + setting definitions.
        foreach ($packages->all() as $slug => $manifest) {
            if (! empty($manifest['roles'])) {
                $roles->registerRoles($manifest['roles'], $slug);
            }
            if (! empty($manifest['settings'])) {
                $settings->registerSettings($manifest['settings'], $slug);
            }
        }

        // 3) Seed menu defaults from registered MenuContributors.
        $createdMenu = $menu->syncDefaults();
        $this->info("Menu items created: {$createdMenu}");

        $packages->forgetCache();

        $this->info('Done.');

        return self::SUCCESS;
    }
}
