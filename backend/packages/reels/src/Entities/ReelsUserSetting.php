<?php

namespace Utd\Reels\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class ReelsUserSetting extends Model
{
    protected $table = 'reels_user_settings';

    protected $fillable = [
        'user_id',
        'all_unique_value',
        'following_unique_value',
        'last_all_reel_id',
        'last_following_reel_id',
    ];

    protected $guarded = [];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
