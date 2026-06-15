<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * A user's override of the default (default-on) notification behaviour for a
 * (category[, channel]) pair. See {@see \App\Services\Notifications\NotificationManager::isMuted()}.
 */
class NotificationPreference extends Model
{
    protected $fillable = [
        'user_id',
        'category',
        'channel',
        'enabled',
    ];

    protected $casts = [
        'enabled' => 'boolean',
    ];
}
