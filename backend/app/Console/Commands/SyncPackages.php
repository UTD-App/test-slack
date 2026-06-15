<?php

namespace App\Console\Commands;

use App\Models\Package;
use App\Services\AdminPermissionRegistry;
use App\Services\MenuService;
use App\Services\PackageRegistry;
use App\Services\RoleService;
use App\Services\SettingService;
use Database\Seeders\AdminPermissionSeeder;
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
        AdminPermissionRegistry $adminPermissions,
    ): int {
        // Ensure the base (core) package row exists.
        Package::firstOrCreate(
            ['slug' => 'base'],
            ['name' => 'Base Project', 'version' => '1.0.0', 'is_core' => true, 'installed_at' => now()],
        );

        // 1) Persist package rows (preserves admin-owned enabled/order).
        $synced = $packages->syncToDatabase();
        $this->info("Packages synced: {$synced}");

        // 2) Flush the base admin-permission catalog, then each module's
        //    roles / settings / admin permissions.
        $adminPermissions->register(config('permissions', []), 'base');

        foreach ($packages->all() as $slug => $manifest) {
            if (! empty($manifest['roles'])) {
                $roles->registerRoles($manifest['roles'], $slug);
            }
            if (! empty($manifest['settings'])) {
                $settings->registerSettings($manifest['settings'], $slug);
            }
            if (! empty($manifest['admin_permissions'])) {
                $adminPermissions->register($manifest['admin_permissions'], $slug);
            }
        }

        // 2b) Auto-discover admin permissions from ENABLED package Filament
        //     resources. A package resource only needs `$permissionPrefix`
        //     (+ optional `$permissionAbilities`) to appear in Roles & Permissions
        //     and be enforceable — no extra wiring. Base (App\) resources are
        //     defined explicitly in config/permissions.php and skipped here.
        try {
            foreach (\Filament\Facades\Filament::getPanel('admin')->getResources() as $resourceClass) {
                if (! is_subclass_of($resourceClass, \App\Filament\Resources\BaseResource::class)) {
                    continue;
                }
                if (str_starts_with($resourceClass, 'App\\')) {
                    continue;
                }
                $prefix = $resourceClass::getPermissionPrefix();
                if (! $prefix) {
                    continue;
                }
                $pkgSlug = \Illuminate\Support\Str::kebab(explode('\\', $resourceClass)[1] ?? 'package');
                $adminPermissions->register([$prefix => $resourceClass::getPermissionAbilities()], $pkgSlug);
            }
        } catch (\Throwable $e) {
            $this->warn("Package permission auto-discovery skipped: {$e->getMessage()}");
        }

        // 3) Grant the default role→permission map (idempotent; only fills roles
        //    that have no grants yet, so admin customisations survive).
        app(AdminPermissionSeeder::class)->run();
        $this->info('Default role permissions ensured.');

        // 4) Seed menu defaults from registered MenuContributors.
        $createdMenu = $menu->syncDefaults();
        $this->info("Menu items created: {$createdMenu}");

        $packages->forgetCache();

        $this->info('Done.');

        return self::SUCCESS;
    }
}
