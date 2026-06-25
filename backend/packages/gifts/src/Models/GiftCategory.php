<?php

namespace Utd\Gifts\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Cache;

class GiftCategory extends Model
{
    protected $fillable = ['title', 'type', 'sort'];

    protected $casts = [
        'title' => 'array',
    ];

    /** Bust the cached catalog whenever a category changes (create/edit/reorder/delete). */
    protected static function booted(): void
    {
        $forget = fn () => Cache::forget('gifts:categories');
        static::saved($forget);
        static::deleted($forget);
    }

    public function gifts(): HasMany
    {
        return $this->hasMany(Gift::class);
    }
}
