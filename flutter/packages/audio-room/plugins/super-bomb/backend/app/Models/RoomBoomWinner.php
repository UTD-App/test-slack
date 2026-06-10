<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoomBoomWinner extends Model
{
    protected $fillable = ['room_boom_reward_id', 'room_boom_id', 'user_id'];

    public function reward(): BelongsTo
    {
        return $this->belongsTo(RoomBoomReward::class, 'room_boom_reward_id');
    }

    public function boom(): BelongsTo
    {
        return $this->belongsTo(RoomBoom::class, 'room_boom_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
