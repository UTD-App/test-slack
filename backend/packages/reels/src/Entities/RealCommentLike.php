<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * A Facebook-style reaction on a reel comment (or reply). Exclusive: one row
 * per (comment_id, user_id); the reaction_type is switched in place.
 */
class RealCommentLike extends Model
{
    protected $table = 'real_comment_likes';

    protected $fillable = ['comment_id', 'user_id', 'reaction_type'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function comment()
    {
        return $this->belongsTo(RealUserComment::class, 'comment_id', 'id');
    }
}
