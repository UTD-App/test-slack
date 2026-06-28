<?php

namespace Utd\Gifts\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Cache;

class Gift extends Model
{
    /** Gift type ids (mirror Eagle): 1 normal … 6 lucky. */
    public const TYPE_NORMAL = 1;
    public const TYPE_LUCKY = 6;

    /** Bust the cached image list whenever a gift changes. */
    protected static function booted(): void
    {
        $forget = fn () => Cache::forget('gifts:images');
        static::saved($forget);
        static::deleted($forget);
    }

    protected $fillable = [
        'name', 'e_name', 'type', 'gift_category_id', 'vip_level', 'price',
        'img', 'show_img', 'show_img2', 'image_type', 'music_gift', 'international_gift',
        'is_play', 'sort', 'enable', 'use_count',
    ];

    protected $casts = [
        'type'               => 'integer',
        'vip_level'          => 'integer',
        'price'              => 'integer',
        'music_gift'         => 'boolean',
        'international_gift'  => 'boolean',
        'is_play'            => 'boolean',
        'enable'             => 'boolean',
        'use_count'          => 'integer',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(GiftCategory::class, 'gift_category_id');
    }

    public function scopeEnabled(Builder $query): Builder
    {
        return $query->where('enable', true);
    }

    public function isLucky(): bool
    {
        return (int) $this->type === self::TYPE_LUCKY;
    }
}
