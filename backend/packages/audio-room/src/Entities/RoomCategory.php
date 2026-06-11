<?php

namespace Utd\AudioRoom\Entities;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RoomCategory extends Model
{
    protected $fillable = ['parent_id', 'name', 'name_en', 'img', 'enable', 'sort'];

    protected $casts = [
        'enable' => 'boolean',
    ];

    public function parent(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(self::class, 'parent_id')->orderBy('sort');
    }

    public function rooms(): HasMany
    {
        return $this->hasMany(Room::class, 'room_type');
    }
}
