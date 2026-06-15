<?php

namespace App\Models;

use App\Facades\Media;
use Illuminate\Database\Eloquent\Model;

class Profile extends Model
{
    protected $fillable = [
        'user_id',
        'avatar',
        'cover',
        'gender',
        'birthday',
        'province',
        'city',
        'country',
    ];

    // Expose `image` (a full public URL) so the Flutter clients — which read
    // `profile.image` — render the stored `avatar` path. Already-absolute URLs
    // pass through untouched; relative paths go through the Media seam.
    protected $appends = ['image'];

    public function getImageAttribute(): ?string
    {
        $avatar = $this->attributes['avatar'] ?? null;
        if (empty($avatar)) {
            return null;
        }
        if (str_starts_with($avatar, 'http://') || str_starts_with($avatar, 'https://')) {
            return $avatar;
        }
        return Media::url($avatar);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
