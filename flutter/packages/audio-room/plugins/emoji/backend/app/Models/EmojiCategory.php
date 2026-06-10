<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EmojiCategory extends Model
{
    protected $guarded = [];

    protected $casts = [
        'title' => 'array',
    ];

    public function emojis(): HasMany
    {
        return $this->hasMany(Emoji::class, 'emoji_category_id')->orderBy('sort');
    }
}
