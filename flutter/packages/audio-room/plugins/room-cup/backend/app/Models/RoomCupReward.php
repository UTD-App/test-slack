<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoomCupReward extends Model
{
    protected $guarded = [];

    public function target(): BelongsTo
    {
        return $this->belongsTo(RoomCupTarget::class, 'room_cup_target_id');
    }
}
