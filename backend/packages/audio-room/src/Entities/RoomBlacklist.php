<?php

namespace Utd\AudioRoom\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoomBlacklist extends Model
{
    protected $table = 'room_blacklist';

    protected $fillable = [
        'room_id', 'user_id', 'banned_by', 'banned_at',
        'duration_seconds', 'expires_at', 'reason', 'is_active',
    ];

    protected $casts = [
        'banned_at' => 'datetime',
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function bannedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'banned_by');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    public function scopeNotExpired(Builder $query): Builder
    {
        return $query->where(function ($q) {
            $q->whereNull('expires_at')
              ->orWhere('expires_at', '>', now());
        });
    }

    public function scopeValid(Builder $query): Builder
    {
        return $query->active()->notExpired();
    }

    public function isValid(): bool
    {
        return $this->is_active && !$this->hasExpired();
    }

    public function hasExpired(): bool
    {
        if ($this->expires_at === null) {
            return false;
        }
        return $this->expires_at->isPast();
    }

    public function getTimeRemaining(): ?int
    {
        if ($this->expires_at === null) {
            return null;
        }
        $remaining = now()->diffInSeconds($this->expires_at, false);
        return max(0, (int) $remaining);
    }
}
