<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class AdminUser extends Authenticatable implements FilamentUser
{
    use Notifiable;

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

    public function roles()
    {
        return $this->belongsToMany(AdminRole::class, 'admin_role_user', 'admin_user_id', 'admin_role_id');
    }

    public function hasRole(string $role): bool
    {
        // Super admin bypasses all role checks
        if ($this->roles()->where('name', 'super_admin')->exists()) {
            return true;
        }
        return $this->roles()->where('name', $role)->exists();
    }

    public function hasAnyRole(array $roles): bool
    {
        if ($this->roles()->where('name', 'super_admin')->exists()) {
            return true;
        }
        return $this->roles()->whereIn('name', $roles)->exists();
    }

    public function isSuperAdmin(): bool
    {
        return $this->roles()->where('name', 'super_admin')->exists();
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->is_active;
    }
}
