<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A single in-app notification row. Language-neutral: holds `type` + `params`,
 * not rendered text. Title/body are produced on read by
 * {@see \App\Http\Resources\NotificationResource} using the registered
 * {@see \App\Services\Notifications\NotificationTypeRegistry} metadata.
 */
class Notification extends Model
{
    /** Audience markers for the notifiable_type column. */
    public const AUDIENCE_USER = 'user';
    public const AUDIENCE_ADMIN = 'admin';

    protected $fillable = [
        'notifiable_type',
        'notifiable_id',
        'type',
        'category',
        'params',
        'data',
        'actor_id',
        'image_url',
        'read_at',
    ];

    protected $casts = [
        'params'  => 'array',
        'data'    => 'array',
        'read_at' => 'datetime',
    ];

    public function notifiable(): BelongsTo
    {
        return $this->belongsTo(User::class, 'notifiable_id');
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }

    public function isRead(): bool
    {
        return $this->read_at !== null;
    }

    public function scopeUnread($query)
    {
        return $query->whereNull('read_at');
    }

    /** In-app notifications for a specific user. */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('notifiable_type', self::AUDIENCE_USER)->where('notifiable_id', $userId);
    }

    /** Dashboard notifications addressed to admins. */
    public function scopeForAdmins($query)
    {
        return $query->where('notifiable_type', self::AUDIENCE_ADMIN);
    }
}
