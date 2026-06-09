<?php

namespace Utd\Moment\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class Moment extends Model
{
    protected $table = 'moment';

    protected $fillable = ['user_id', 'description', 'img'];

    protected $guarded = [];

    public function comments()
    {
        return $this->hasMany(MomentCommint::class, 'moment_id', 'id');
    }

    public function likes()
    {
        return $this->hasMany(MomentLikes::class, 'moment_id', 'id');
    }

    public function images()
    {
        return $this->hasMany(MomentGallery::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // NOTE(gap): in Eagle, Moment::gifts() was belongsToMany(App\Models\Gift, 'moment_user_gifts').
    // Deferred until the Gifts package is installed (see NOTES_GAPS.md → "gifting").

    public function scopeLikeExists($query, $userId)
    {
        return $query->withExists(['likes' => function ($query) use ($userId) {
            $query->where('user_id', $userId);
        }]);
    }

    /**
     * Eagle feed ordering: moments the viewer hasn't liked yet float to the top
     * (CASE WHEN liked THEN 1 ELSE 0 END ASC → not-liked first), then most recent
     * first. Portable (EXISTS works on MySQL + SQLite).
     */
    public function scopeFeedOrder($query, $userId)
    {
        return $query
            ->orderByRaw(
                '(EXISTS (SELECT 1 FROM moment_user_likes'
                . ' WHERE moment_user_likes.moment_id = moment.id'
                . ' AND moment_user_likes.user_id = ?)) ASC',
                [$userId]
            )
            ->orderBy('created_at', 'desc');
    }

    /**
     * Minimal user eager-load for feeds.
     *
     * NOTE(gap): Eagle's withUser() selected many streaming columns + relations
     * from not-yet-migrated packages. Reduced to the Base User shape.
     */
    public function scopeWithUser($query)
    {
        return $query->with(['user' => fn ($q) => $q
            ->select(['id', 'uuid', 'name', 'avatar', 'gender'])
            ->with('profile:id,user_id,avatar')]);
    }
}
