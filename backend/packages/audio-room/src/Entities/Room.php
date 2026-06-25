<?php

namespace Utd\AudioRoom\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Room extends Model
{
    protected $fillable = [
        'num_id', 'user_id', 'room_name', 'room_cover', 'room_intro',
        'room_rule', 'room_background', 'room_pass', 'room_type',
        'room_class', 'type', 'mode', 'room_status', 'is_afk',
        'is_comment_closed', 'free_mic', 'max_admin', 'pinned_message',
        'empty_seat_icon', 'locked_seat_icon',
    ];

    protected $casts = [
        'num_id' => 'integer',
        'user_id' => 'integer',
        'mode' => 'integer',
        'room_status' => 'integer',
        'room_type' => 'integer',
        'room_class' => 'integer',
        'max_admin' => 'integer',
        'is_afk' => 'boolean',
        'is_comment_closed' => 'boolean',
        'free_mic' => 'boolean',
        'pinned_message' => 'array',
    ];

    protected $hidden = ['room_pass'];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function categoryType(): BelongsTo
    {
        return $this->belongsTo(RoomCategory::class, 'room_type');
    }

    public function categoryClass(): BelongsTo
    {
        return $this->belongsTo(RoomCategory::class, 'room_class');
    }

    public function visitors(): HasMany
    {
        return $this->hasMany(RoomVisitor::class);
    }

    public function administrators(): HasMany
    {
        return $this->hasMany(RoomAdministrator::class);
    }

    public function blacklist(): HasMany
    {
        return $this->hasMany(RoomBlacklist::class);
    }

    public function isOwner(int $userId): bool
    {
        return $this->user_id === $userId;
    }

    public function isAdmin(int $userId): bool
    {
        return $this->administrators()->where('user_id', $userId)->exists();
    }

    public function isOwnerOrAdmin(int $userId): bool
    {
        return $this->isOwner($userId) || $this->isAdmin($userId);
    }

    public function hasPassword(): bool
    {
        return !empty($this->room_pass);
    }
}
