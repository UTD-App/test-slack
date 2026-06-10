<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TotalRoomGift extends Model
{
    protected $fillable = ['room_id', 'current_total', 'number_of_visitors'];

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }

    public function roomBooms(): HasMany
    {
        return $this->hasMany(RoomBoom::class, 'total_room_gift_id');
    }
}
