<?php

namespace Utd\Gifts\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

/**
 * A sender/receiver level definition (badge). `kind` is 'sender' or 'receiver';
 * `threshold` is the accumulated EXP required to reach this `level`.
 */
class GiftLevel extends Model
{
    public const KIND_SENDER = 'sender';
    public const KIND_RECEIVER = 'receiver';

    protected $fillable = ['kind', 'level', 'threshold', 'title', 'img', 'color'];

    protected $casts = [
        'level'     => 'integer',
        'threshold' => 'integer',
        'title'     => 'array',
    ];

    /** Bust the cached level table whenever a level changes. */
    protected static function booted(): void
    {
        $forget = fn () => Cache::forget('gifts:levels');
        static::saved($forget);
        static::deleted($forget);
    }
}
