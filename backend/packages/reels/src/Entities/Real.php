<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class Real extends Model
{
    protected $table = 'reals';

    protected $fillable = ['user_id', 'description', 'url', 'sub_video', 'share_num'];

    protected $guarded = [];

    protected static function boot()
    {
        parent::boot();

        self::creating(function ($model) {
            if ($model->description === null) {
                $model->description = '';
            }
        });
    }

    /**
     * Category associations (pivot rows). belongsToMany in Eagle pointed at the
     * `interests` catalog; the Base has no such catalog yet, so we expose the raw
     * pivot. Sync happens via RealsService::syncCategories(). See NOTES_GAPS.
     */
    public function categories()
    {
        return $this->hasMany(RealCategory::class, 'real_id', 'id');
    }

    public function comments()
    {
        return $this->hasMany(RealUserComment::class, 'real_id', 'id');
    }

    public function likes()
    {
        return $this->hasMany(RealUserLike::class, 'real_id', 'id');
    }

    public function views()
    {
        return $this->hasMany(RealUserView::class, 'real_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function scopeLikeExists($query, $userId)
    {
        return $query->withExists(['likes' => function ($query) use ($userId) {
            $query->where('user_id', $userId);
        }]);
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
            ->with('profile:id,user_id,avatar,birthday')]);
    }
}
