<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Emoji extends Model
{
    protected $guarded = [];

    public function category(): BelongsTo
    {
        return $this->belongsTo(EmojiCategory::class, 'emoji_category_id');
    }

    public function scopeEnabled(Builder $query): Builder
    {
        return $query->where('enable', 1);
    }
}
