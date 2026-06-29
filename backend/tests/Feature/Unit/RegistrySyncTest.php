<?php

namespace Tests\Feature\Unit;

use App\Models\AdminPermission;
use App\Models\PackageSetting;
use App\Models\Role;
use App\Models\User;
use App\Services\AdminPermissionRegistry;
use App\Services\RoleService;
use App\Services\SettingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/**
 * The idempotent definition-sync services: SettingService (package setting
 * definitions), RoleService (roles + user grants), AdminPermissionRegistry
 * (granular admin permission catalog). Admin-owned values/grants are preserved.
 */
class RegistrySyncTest extends TestCase
{
    use RefreshDatabase;

    // ── SettingService ────────────────────────────────────────────────────────

    public function test_register_settings_upserts_definitions(): void
    {
        $service = app(SettingService::class);
        $service->registerSettings([
            ['key' => 'gifts.enabled', 'type' => 'bool', 'default' => true, 'label_key' => 'gifts.enabled_label'],
        ], 'gifts');

        $row = PackageSetting::where('key', 'gifts.enabled')->firstOrFail();
        $this->assertSame('gifts', $row->package);
        $this->assertSame('bool', $row->type);
        $this->assertSame('gifts.enabled_label', $row->label_key);
    }

    public function test_register_settings_defaults_package_to_base_and_type_to_bool(): void
    {
        app(SettingService::class)->registerSettings([['key' => 'feature.x']]);

        $row = PackageSetting::where('key', 'feature.x')->firstOrFail();
        $this->assertSame('base', $row->package);
        $this->assertSame('bool', $row->type);
    }

    public function test_register_settings_skips_entries_without_key(): void
    {
        app(SettingService::class)->registerSettings([
            ['type' => 'bool'],
            ['key' => '', 'type' => 'bool'],
            ['key' => 'ok'],
        ]);

        $this->assertDatabaseCount('package_settings', 1);
    }

    public function test_register_settings_is_idempotent_and_updates_definition(): void
    {
        $service = app(SettingService::class);
        $service->registerSettings([['key' => 'k', 'type' => 'bool', 'default' => false]]);
        $service->registerSettings([['key' => 'k', 'type' => 'string', 'default' => 'hi']]);

        $this->assertDatabaseCount('package_settings', 1);
        $row = PackageSetting::where('key', 'k')->firstOrFail();
        $this->assertSame('string', $row->type);
        $this->assertSame('hi', $row->default_value); // cast to array; scalar passes through
    }

    public function test_defaults_returns_key_to_default_map_optionally_scoped(): void
    {
        $service = app(SettingService::class);
        $service->registerSettings([['key' => 'a', 'default' => 1]], 'gifts');
        $service->registerSettings([['key' => 'b', 'default' => 2]], 'moment');

        $all = $service->defaults();
        $this->assertSame(['a' => 1, 'b' => 2], $all);

        $scoped = $service->defaults('gifts');
        $this->assertSame(['a' => 1], $scoped);
    }

    // ── RoleService ───────────────────────────────────────────────────────────

    public function test_register_roles_from_strings_and_arrays(): void
    {
        $service = app(RoleService::class);
        $service->registerRoles(['admin', ['key' => 'vip', 'display_name' => 'VIP Member']], 'base');

        $this->assertDatabaseHas('roles', ['key' => 'admin', 'display_name' => 'admin', 'package' => 'base']);
        $this->assertDatabaseHas('roles', ['key' => 'vip', 'display_name' => 'VIP Member']);
    }

    public function test_register_roles_is_idempotent(): void
    {
        $service = app(RoleService::class);
        $service->registerRoles(['admin']);
        $service->registerRoles(['admin']);

        $this->assertSame(1, Role::where('key', 'admin')->count());
    }

    public function test_assign_and_has_and_remove_role(): void
    {
        $service = app(RoleService::class);
        $service->registerRoles(['vip']);
        $user = User::factory()->create();

        $this->assertFalse($service->hasRole($user, 'vip'));

        $service->assignRole($user, 'vip');
        $this->assertTrue($service->hasRole($user, 'vip'));
        $this->assertSame(['vip'], $service->getUserRoles($user)->all());

        $service->removeRole($user, 'vip');
        $this->assertFalse($service->hasRole($user, 'vip'));
    }

    public function test_assign_role_is_not_duplicated(): void
    {
        $service = app(RoleService::class);
        $service->registerRoles(['vip']);
        $user = User::factory()->create();

        $service->assignRole($user, 'vip');
        $service->assignRole($user, 'vip');

        $this->assertSame(1, $user->roles()->count());
    }

    public function test_assign_unknown_role_is_a_noop(): void
    {
        $service = app(RoleService::class);
        $user = User::factory()->create();

        $service->assignRole($user, 'ghost'); // no such role

        $this->assertSame(0, $user->roles()->count());
    }

    // ── AdminPermissionRegistry ───────────────────────────────────────────────

    public function test_admin_permissions_expand_group_ability_into_keys(): void
    {
        $registry = app(AdminPermissionRegistry::class);
        $registry->register(['users' => ['view', 'ban'], 'settings' => ['update']], 'base');

        $this->assertDatabaseHas('admin_permissions', ['key' => 'users.view', 'group' => 'users', 'label_key' => 'admin.ability_view']);
        $this->assertDatabaseHas('admin_permissions', ['key' => 'users.ban', 'group' => 'users', 'label_key' => 'admin.ability_ban']);
        $this->assertDatabaseHas('admin_permissions', ['key' => 'settings.update', 'group' => 'settings']);
        $this->assertSame(3, AdminPermission::count());
    }

    public function test_admin_permissions_default_package_to_base(): void
    {
        app(AdminPermissionRegistry::class)->register(['users' => ['view']]);

        $this->assertSame('base', AdminPermission::where('key', 'users.view')->value('package'));
    }

    public function test_admin_permissions_register_is_idempotent(): void
    {
        $registry = app(AdminPermissionRegistry::class);
        $registry->register(['users' => ['view']]);
        $registry->register(['users' => ['view']]);

        $this->assertSame(1, AdminPermission::where('key', 'users.view')->count());
    }

    public function test_admin_permission_keys_are_cached_and_busted_on_register(): void
    {
        $registry = app(AdminPermissionRegistry::class);
        $registry->register(['users' => ['view']]);

        $this->assertSame(['users.view'], $registry->keys());

        $registry->register(['users' => ['ban']]); // register() forgets the cache

        $keys = $registry->keys();
        sort($keys);
        $this->assertSame(['users.ban', 'users.view'], $keys);
    }

    public function test_admin_permissions_grouped(): void
    {
        $registry = app(AdminPermissionRegistry::class);
        $registry->register(['users' => ['view', 'ban'], 'settings' => ['update']]);

        $grouped = $registry->grouped();

        $this->assertCount(2, $grouped['users']);
        $this->assertCount(1, $grouped['settings']);
    }
}
