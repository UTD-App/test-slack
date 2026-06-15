<?php

namespace Database\Seeders;

use App\Models\AdminPermission;
use App\Models\AdminRole;
use App\Services\AdminPermissionRegistry;
use Illuminate\Database\Seeder;

/**
 * Grants the DEFAULT role→permission map so the dashboard behaves exactly as it
 * did under the old hardcoded role checks. Idempotent and SAFE to re-run:
 *
 *  - The three editable roles get defaults ONLY if they currently have no grants,
 *    so any permissions an admin tuned via the UI are never overwritten.
 *  - super_admin always receives every permission (cosmetic — it bypasses all
 *    checks anyway), so newly added package permissions show as granted for it.
 *
 * Runs from DatabaseSeeder (fresh installs) and from `utd:sync-packages`
 * (assembled environments), AFTER the permission catalog has been synced.
 */
class AdminPermissionSeeder extends Seeder
{
    /** role name => permission groups granted by default (all abilities in each group). */
    private const DEFAULTS = [
        'user_manager'     => ['users', 'notifications'],
        'settings_manager' => ['settings', 'languages', 'pages', 'menu', 'stac'],
        'content_manager'  => ['pages'],
    ];

    public function run(): void
    {
        // Ensure the base catalog exists so plain `db:seed` works standalone
        // (utd:sync-packages also registers it + package catalogs beforehand —
        // updateOrCreate makes this re-registration harmless).
        app(AdminPermissionRegistry::class)->register(config('permissions', []), 'base');

        $byGroup = AdminPermission::all()->groupBy('group');

        foreach (self::DEFAULTS as $roleName => $groups) {
            $role = AdminRole::where('name', $roleName)->first();

            // Skip missing roles and any role an admin has already customised.
            if (! $role || $role->permissions()->exists()) {
                continue;
            }

            $ids = collect($groups)
                ->flatMap(fn (string $g) => ($byGroup[$g] ?? collect())->pluck('id'))
                ->all();

            $role->permissions()->syncWithoutDetaching($ids);
        }

        // super_admin: keep it holding every permission (additive, never strips).
        $superAdmin = AdminRole::where('name', 'super_admin')->first();
        if ($superAdmin) {
            $superAdmin->permissions()->syncWithoutDetaching(AdminPermission::pluck('id')->all());
        }
    }
}
