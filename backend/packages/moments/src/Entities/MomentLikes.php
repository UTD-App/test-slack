<?php

namespace Utd\Moment\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class MomentLikes extends Model
{
    protected $table = 'moment_user_likes';

    protected $fillable = ['user_id', 'moment_id'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function moment()
    {
        return $this->hasOne(Moment::class, 'id', 'moment_id');
    }

    public function comments()
    {
        return $this->hasMany(MomentCommint::class, 'moment_id', 'moment_id');
    }
}
