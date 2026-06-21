<?php

namespace App\Models;

use App\Models\Concerns\HasTranslations;
use Illuminate\Database\Eloquent\Model;

/**
 * Static content page (privacy policy, about us, …). Keyed by `key`; title/body
 * are localized maps ({en, ar, fr, …}) keyed by any active language code. Edited
 * from the admin Pages resource (TranslatableField) and served to the app via
 * GET /page/{key}, which returns the value resolved for the request locale
 * ({@see HasTranslations::tr()}).
 */
class Page extends Model
{
    use HasTranslations;

    protected $fillable = ['key', 'title', 'body'];

    protected $casts = [
        'title' => 'array',
        'body'  => 'array',
    ];
}
