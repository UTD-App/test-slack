<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class RealUserLike extends Model
{
    protected $table = 'real_user_likes';

    protected $fillable = ['user_id', 'real_id', 'reaction_type'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function real()
    {
        return $this->hasOne(Real::class, 'id', 'real_id');
    }
}
