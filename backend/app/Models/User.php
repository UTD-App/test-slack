<?php

namespace App\Models;

use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $guarded = ['id'];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'status' => 'boolean',
        'is_points_first' => 'boolean',
        'is_logout' => 'boolean',
    ];

    protected static function booted(): void
    {
        // Every user must have a UID. The app/API register flow doesn't set one
        // (the client's `uuid` goes to `firebase_uuid`), so generate a short,
        // unique 7-digit number here when none was provided. The admin panel
        // supplies its own (required field), which is preserved as-is.
        static::creating(function (User $user) {
            if (blank($user->uuid)) {
                do {
                    $uuid = (string) random_int(1000000, 9999999);
                } while (static::withTrashed()->where('uuid', $uuid)->exists());

                $user->uuid = $uuid;
            }
        });
    }

    public function setPasswordAttribute($value)
    {
        if ($value) {
            $this->attributes['password'] = bcrypt($value);
        }
    }

    public function country()
    {
        return $this->belongsTo(Country::class);
    }

    public function profile()
    {
        return $this->hasOne(Profile::class);
    }

    public function roles()
    {
        return $this->belongsToMany(Role::class, 'role_user');
    }

    public function settings()
    {
        return $this->hasMany(UserSetting::class);
    }

    public function hasRole(string $key): bool
    {
        return $this->roles()->where('key', $key)->exists();
    }

    public function getAvatarAttribute()
    {
        return $this->profile?->avatar;
    }
}
