<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class CharismaLevel extends Model
{
    protected $guarded = [];

    protected static function booted(): void
    {
        static::saved(fn () => Cache::forget('charisma_levels'));
        static::deleted(fn () => Cache::forget('charisma_levels'));
    }
}
