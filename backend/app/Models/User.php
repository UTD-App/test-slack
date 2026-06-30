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
        'online_time' => 'datetime',
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

    /** Window (minutes) within which a user counts as "online" since last activity. */
    public const ONLINE_WINDOW_MINUTES = 5;

    /**
     * Online = had request activity within the window. `online_time` is bumped
     * (cache-throttled) by the UpdateLastSeen middleware on authenticated requests.
     */
    public function isOnline(?int $minutes = null): bool
    {
        $minutes ??= self::ONLINE_WINDOW_MINUTES;

        return $this->online_time !== null
            && $this->online_time->gt(now()->subMinutes($minutes));
    }

    /**
     * Hash the password on assignment — but idempotently and non-destructively:
     *   - blank (null/'') is ignored, so "leave blank to keep current" flows
     *     (e.g. admin edit) don't wipe the password.
     *   - a value that is ALREADY a hash is stored as-is, so assigning an
     *     already-hashed value no longer double-hashes it (the prior footgun).
     *   - plaintext is bcrypt'd.
     */
    public function setPasswordAttribute($value): void
    {
        if (blank($value)) {
            return;
        }

        $alreadyHashed = is_string($value) && password_get_info($value)['algo'] !== null;
        $this->attributes['password'] = $alreadyHashed ? $value : bcrypt($value);
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
