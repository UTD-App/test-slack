<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoomBoomTopContributor extends Model
{
    protected $fillable = ['room_boom_level_id', 'total_room_gift_id', 'user_id', 'price'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
