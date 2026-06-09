<?php

namespace App\Services;

use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Collection;

class RoleService
{
    public function registerRoles(array $roles, ?string $package = null): void
    {
        foreach ($roles as $role) {
            $key = is_string($role) ? $role : ($role['key'] ?? '');
            $displayName = is_string($role) ? $key : ($role['display_name'] ?? $key);

            Role::firstOrCreate(
                ['key' => $key],
                ['display_name' => $displayName, 'package' => $package],
            );
        }
    }

    public function assignRole(User $user, string $key): void
    {
        $role = Role::where('key', $key)->first();
        if ($role && !$user->roles()->where('role_id', $role->id)->exists()) {
            $user->roles()->attach($role->id);
        }
    }

    public function removeRole(User $user, string $key): void
    {
        $role = Role::where('key', $key)->first();
        if ($role) {
            $user->roles()->detach($role->id);
        }
    }

    public function hasRole(User $user, string $key): bool
    {
        return $user->roles()->where('key', $key)->exists();
    }

    public function getUserRoles(User $user): Collection
    {
        return $user->roles()->pluck('key');
    }
}
