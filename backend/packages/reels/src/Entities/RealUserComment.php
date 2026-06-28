<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class RealUserComment extends Model
{
    protected $table = 'real_user_comments';

    protected $fillable = ['user_id', 'real_id', 'comment', 'parent_id'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function real()
    {
        return $this->belongsTo(Real::class, 'real_id', 'id');
    }

    /** The comment this one replies to (null = top-level). */
    public function parent()
    {
        return $this->belongsTo(RealUserComment::class, 'parent_id', 'id');
    }

    /** Direct replies to this comment (one level). */
    public function replies()
    {
        return $this->hasMany(RealUserComment::class, 'parent_id', 'id');
    }

    /** Facebook-style reactions on this comment (one per user). */
    public function likes()
    {
        return $this->hasMany(RealCommentLike::class, 'comment_id', 'id');
    }
}
