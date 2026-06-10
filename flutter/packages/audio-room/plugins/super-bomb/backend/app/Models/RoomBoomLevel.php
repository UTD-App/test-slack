<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RoomBoomLevel extends Model
{
    protected $guarded = [];

    protected static function booted(): void
    {
        static::saved(fn () => \Cache::forget('room_boom_levels'));
        static::saved(fn () => \Cache::forget('boom_levels:videos'));
        static::deleted(fn () => \Cache::forget('room_boom_levels'));
        static::deleted(fn () => \Cache::forget('boom_levels:videos'));
    }

    public function roomBoomRewards(): HasMany
    {
        return $this->hasMany(RoomBoomReward::class);
    }

    public function roomBooms(): HasMany
    {
        return $this->hasMany(RoomBoom::class);
    }
}
