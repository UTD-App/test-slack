<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoomBoom extends Model
{
    protected $fillable = [
        'total_room_gift_id', 'room_boom_level_id', 'started_at', 'ended_at',
        'total_gifts_value', 'trigger_gift_id', 'final_gift_id',
    ];

    public function roomBoomLevel(): BelongsTo
    {
        return $this->belongsTo(RoomBoomLevel::class);
    }

    public function totalRoomGift(): BelongsTo
    {
        return $this->belongsTo(TotalRoomGift::class, 'total_room_gift_id');
    }
}
