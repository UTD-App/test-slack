<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class RoomBoomReward extends Model
{
    protected $fillable = ['room_boom_level_id', 'target', 'target_type', 'priority', 'quantity', 'expire_days'];

    public function level(): BelongsTo
    {
        return $this->belongsTo(RoomBoomLevel::class, 'room_boom_level_id');
    }

    public function ware(): HasOne
    {
        return $this->hasOne(Ware::class, 'id', 'target');
    }

    public function gift(): HasOne
    {
        return $this->hasOne(Gift::class, 'id', 'target');
    }
}
