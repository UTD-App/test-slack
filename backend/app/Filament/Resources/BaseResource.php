<?php

namespace App\Filament\Resources;

use App\Filament\Concerns\GatedByPackage;
use App\Models\AdminUser;
use Filament\Resources\Resource;
use Illuminate\Database\Eloquent\Model;

/**
 * Shared base for all admin resources (Base + package modules).
 *
 * Access is PERMISSION-based: a resource declares `$permissionPrefix` (e.g.
 * 'users') and the standard Filament abilities resolve to granular permission
 * keys — `<prefix>.view|create|update|delete`. `super_admin` always passes
 * (handled in AdminUser::hasPermission + the global Gate::before).
 *
 * Back-compat: if `$permissionPrefix` is null, the resource falls back to the
 * legacy coarse role gate (`$accessRoles`), so un-migrated resources keep working.
 *
 * Package-owned resources also vanish the instant their package is disabled —
 * see [GatedByPackage]. Standalone packages set `$packageSlug`; legacy
 * `Modules\<Name>\...` resources are detected automatically.
 *
 * Usage in a package:
 *   class GiftResource extends \App\Filament\Resources\BaseResource {
 *       protected static ?string $packageSlug = 'gifts';
 *       protected static ?string $permissionPrefix = 'gifts';
 *       ...
 *   }
 */
abstract class BaseResource extends Resource
{
    use GatedByPackage;

    /** Package slug this resource belongs to (null = first-party, always on). */
    protected static ?string $packageSlug = null;

    /**
     * Permission group for this resource. When set, abilities resolve to
     * `<prefix>.<ability>`. Leave null to use the role fallback.
     */
    protected static ?string $permissionPrefix = null;

    /**
     * The abilities this resource exposes. Drives BOTH gating and the permission
     * catalog (package resources are auto-discovered into Roles & Permissions from
     * these). Default is full CRUD; override for read-only / custom resources.
     *
     * @var array<int, string>
     */
    protected static array $permissionAbilities = ['view', 'create', 'update', 'delete'];

    /**
     * Legacy fallback: admin roles allowed when `$permissionPrefix` is null.
     * `super_admin` always has access.
     */
    protected static array $accessRoles = ['super_admin'];

    /** Public accessor for the permission group (used by the sync auto-discovery). */
    public static function getPermissionPrefix(): ?string
    {
        return static::$permissionPrefix;
    }

    /**
     * Public accessor for the exposed abilities (used by the sync auto-discovery).
     *
     * @return array<int, string>
     */
    public static function getPermissionAbilities(): array
    {
        return static::$permissionAbilities;
    }

    /** The current panel user, if it is an AdminUser. */
    protected static function adminUser(): ?AdminUser
    {
        $user = filament()->auth()->user();

        return $user instanceof AdminUser ? $user : null;
    }

    /**
     * Resolve one ability for this resource. Permission-based when a prefix is
     * set; otherwise the legacy role gate (every ability maps to the same check).
     */
    protected static function canAbility(string $ability): bool
    {
        $user = static::adminUser();
        if (! $user) {
            return false;
        }

        if (static::$permissionPrefix === null) {
            return $user->hasAnyRole(array_values(array_unique(
                array_merge(['super_admin'], static::$accessRoles),
            )));
        }

        return $user->hasPermission(static::$permissionPrefix . '.' . $ability);
    }

    public static function canAccess(): bool
    {
        // Package-owned resources vanish the instant their package is disabled.
        if (! static::packageIsEnabled()) {
            return false;
        }

        return static::canAbility('view');
    }

    public static function canViewAny(): bool
    {
        return static::canAbility('view');
    }

    public static function canView(Model $record): bool
    {
        return static::canAbility('view');
    }

    public static function canCreate(): bool
    {
        return static::canAbility('create');
    }

    public static function canEdit(Model $record): bool
    {
        return static::canAbility('update');
    }

    public static function canDelete(Model $record): bool
    {
        return static::canAbility('delete');
    }

    public static function canDeleteAny(): bool
    {
        return static::canAbility('delete');
    }
}
