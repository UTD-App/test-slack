<?php

namespace App\Models;

use App\Support\Auditable;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class AdminUser extends Authenticatable implements FilamentUser
{
    use Notifiable, Auditable;

    protected $table = 'admin_users';

    protected $fillable = [
        'name',
        'email',
        'password',
        'avatar',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'is_active'         => 'boolean',
        'email_verified_at' => 'datetime',
    ];

    /** Per-request memo of this admin's effective permission keys (union of roles). */
    private ?array $permissionKeyCache = null;

    public function roles()
    {
        return $this->belongsToMany(AdminRole::class, 'admin_role_user', 'admin_user_id', 'admin_role_id');
    }

    public function hasRole(string $role): bool
    {
        // Super admin bypasses all role checks
        if ($this->isSuperAdmin()) {
            return true;
        }
        return $this->roles()->where('name', $role)->exists();
    }

    public function hasAnyRole(array $roles): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        return $this->roles()->whereIn('name', $roles)->exists();
    }

    public function isSuperAdmin(): bool
    {
        return $this->roles()->where('name', 'super_admin')->exists();
    }

    /**
     * Effective permission keys = union of all this admin's roles' permissions.
     * Loaded once per request (one eager query) and memoised.
     *
     * @return array<int, string>
     */
    public function permissionKeys(): array
    {
        if ($this->permissionKeyCache !== null) {
            return $this->permissionKeyCache;
        }

        $this->loadMissing('roles.permissions');

        return $this->permissionKeyCache = $this->roles
            ->flatMap(fn (AdminRole $role) => $role->permissions->pluck('key'))
            ->unique()
            ->values()
            ->all();
    }

    /** Super admin → always true. Otherwise the key must be in the effective set. */
    public function hasPermission(string $key): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        return in_array($key, $this->permissionKeys(), true);
    }

    /** @param array<int, string> $keys */
    public function hasAnyPermission(array $keys): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        return (bool) array_intersect($keys, $this->permissionKeys());
    }

    /** @param array<int, string> $keys */
    public function hasAllPermissions(array $keys): bool
    {
        if ($this->isSuperAdmin()) {
            return true;
        }
        return ! array_diff($keys, $this->permissionKeys());
    }

    /** True if $ability is a known permission key in the synced catalog. */
    public function isKnownPermission(string $ability): bool
    {
        return in_array($ability, app(\App\Services\AdminPermissionRegistry::class)->keys(), true);
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->is_active;
    }
}
