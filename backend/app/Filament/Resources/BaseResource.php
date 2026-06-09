<?php

namespace App\Filament\Resources;

use App\Filament\Concerns\GatedByPackage;
use Filament\Resources\Resource;

/**
 * Shared base for all admin resources (Base + package modules).
 *
 * Centralizes role-gating so resources only declare which roles may access them
 * instead of repeating the `filament()->auth()->user()?->hasAnyRole([...])` block.
 * `super_admin` always has access.
 *
 * Package-owned resources also vanish the instant their package is disabled —
 * see [GatedByPackage]. Standalone packages set `$packageSlug`; legacy
 * `Modules\<Name>\...` resources are detected automatically.
 *
 * Usage in a package:
 *   class AudioRoomResource extends \App\Filament\Resources\BaseResource {
 *       protected static ?string $packageSlug = 'audio-room';
 *       protected static array $accessRoles = ['audio-room.manager'];
 *       protected static ?string $navigationGroup = 'Audio Room';
 *       ...
 *   }
 */
abstract class BaseResource extends Resource
{
    use GatedByPackage;

    /** Package slug this resource belongs to (null = first-party, always on). */
    protected static ?string $packageSlug = null;

    /**
     * Admin-panel roles (admin_roles) allowed to access this resource.
     * `super_admin` always has access.
     */
    protected static array $accessRoles = ['super_admin'];

    public static function canAccess(): bool
    {
        // Package-owned resources vanish the instant their package is disabled.
        if (! static::packageIsEnabled()) {
            return false;
        }

        $user = filament()->auth()->user();
        if (! $user instanceof \App\Models\AdminUser) {
            return false;
        }

        return $user->hasAnyRole(array_values(array_unique(
            array_merge(['super_admin'], static::$accessRoles),
        )));
    }
}
