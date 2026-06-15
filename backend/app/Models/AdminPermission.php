<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * One granular admin permission, e.g. key `users.ban` (group `users`).
 * Catalog rows are created/updated by AdminPermissionRegistry during
 * `utd:sync-packages`; roles are granted permissions via admin_permission_role.
 */
class AdminPermission extends Model
{
    protected $guarded = [];

    public function roles()
    {
        return $this->belongsToMany(
            AdminRole::class,
            'admin_permission_role',
            'admin_permission_id',
            'admin_role_id',
        );
    }
}
