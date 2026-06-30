<?php

namespace Utd\Moment\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class MomentComment extends Model
{
    protected $table = 'moment_user_comments';

    protected $fillable = ['user_id', 'moment_id', 'comment', 'parent_id'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function moment()
    {
        return $this->belongsTo(Moment::class, 'moment_id', 'id');
    }

    /** The comment this one replies to (null = top-level). */
    public function parent()
    {
        return $this->belongsTo(MomentComment::class, 'parent_id', 'id');
    }

    /** Direct replies to this comment (one level). */
    public function replies()
    {
        return $this->hasMany(MomentComment::class, 'parent_id', 'id');
    }

    /** Facebook-style reactions on this comment (one per user). */
    public function likes()
    {
        return $this->hasMany(MomentCommentLikes::class, 'comment_id', 'id');
    }
}
