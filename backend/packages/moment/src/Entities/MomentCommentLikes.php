<?php

namespace Utd\Moment\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * A Facebook-style reaction on a moment comment (or reply). Exclusive: one row
 * per (comment_id, user_id); the reaction_type is switched in place.
 */
class MomentCommentLikes extends Model
{
    protected $table = 'moment_comment_likes';

    protected $fillable = ['comment_id', 'user_id', 'reaction_type'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function comment()
    {
        return $this->belongsTo(MomentCommint::class, 'comment_id', 'id');
    }
}
