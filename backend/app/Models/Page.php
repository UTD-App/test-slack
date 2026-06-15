<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Static content page (privacy policy, about us, …). Keyed by `key`; title/body
 * are localized arrays ({en, ar}). Edited from the admin Pages resource and
 * served to the app via GET /page/{key}.
 */
class Page extends Model
{
    protected $fillable = ['key', 'title', 'body'];

    protected $casts = [
        'title' => 'array',
        'body'  => 'array',
    ];
}
