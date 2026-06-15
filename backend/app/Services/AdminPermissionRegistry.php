<?php

namespace App\Services;

use App\Models\AdminPermission;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;

/**
 * Registers/syncs the granular ADMIN permission catalog (admin_permissions).
 * Mirrors RoleService: definitions are idempotently upserted; the role↔permission
 * GRANTS are owned by admins and never touched here.
 *
 * Input shape is the compact map `group => [abilities]`, e.g.
 *   ['users' => ['view', 'create', 'ban'], 'settings' => ['view', 'update']]
 * which expands to keys `users.view`, `users.ban`, … with label_key
 * `admin.ability_<ability>` (shared ability labels; the group heading uses
 * `admin.permgroup_<group>`).
 */
class AdminPermissionRegistry
{
    private const KEYS_CACHE = 'admin_permission_keys';

    /**
     * @param array<string, array<int, string>> $groups  group => [abilities]
     */
    public function register(array $groups, ?string $package = null): void
    {
        foreach ($groups as $group => $abilities) {
            foreach ($abilities as $ability) {
                AdminPermission::updateOrCreate(
                    ['key' => "{$group}.{$ability}"],
                    [
                        'group'     => $group,
                        'label_key' => "admin.ability_{$ability}",
                        'package'   => $package ?? 'base',
                    ],
                );
            }
        }

        $this->forgetCache();
    }

    /** @return Collection<int, AdminPermission> */
    public function all(): Collection
    {
        return AdminPermission::orderBy('group')->orderBy('key')->get();
    }

    /** @return array<string, Collection<int, AdminPermission>> group => permissions */
    public function grouped(): array
    {
        return $this->all()->groupBy('group')->all();
    }

    /**
     * Flat list of every known permission key (cached) — used by the Gate resolver
     * to decide whether an ability string is one of ours.
     *
     * @return array<int, string>
     */
    public function keys(): array
    {
        return Cache::rememberForever(self::KEYS_CACHE, fn (): array => AdminPermission::pluck('key')->all());
    }

    public function forgetCache(): void
    {
        Cache::forget(self::KEYS_CACHE);
    }
}
