<?php

namespace App\Models;

use App\Support\Auditable;
use Illuminate\Database\Eloquent\Model;

class AdminRole extends Model
{
    use Auditable;

    protected $guarded = [];

    public function users()
    {
        return $this->belongsToMany(AdminUser::class, 'admin_role_user', 'admin_role_id', 'admin_user_id');
    }

    public function permissions()
    {
        return $this->belongsToMany(
            AdminPermission::class,
            'admin_permission_role',
            'admin_role_id',
            'admin_permission_id',
        );
    }

    public function hasPermission(string $key): bool
    {
        return $this->permissions()->where('key', $key)->exists();
    }
}
