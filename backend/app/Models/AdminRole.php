<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdminRole extends Model
{
    protected $guarded = [];

    public function users()
    {
        return $this->belongsToMany(AdminUser::class, 'admin_role_user', 'admin_role_id', 'admin_user_id');
    }
}
