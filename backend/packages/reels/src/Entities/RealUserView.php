<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class RealUserView extends Model
{
    protected $table = 'real_user_views';

    protected $fillable = ['user_id', 'real_id', 'duration_in_minute'];

    protected $guarded = [];

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function real()
    {
        return $this->belongsTo(Real::class, 'real_id', 'id');
    }
}
