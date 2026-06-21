<?php

namespace App\Models;

use App\Services\PackageRegistry;
use App\Support\Auditable;
use Illuminate\Database\Eloquent\Model;

class Package extends Model
{
    use Auditable;

    protected $guarded = [];

    protected $casts = [
        'enabled'      => 'boolean',
        'is_core'      => 'boolean',
        'dependencies' => 'array',
        'meta'         => 'array',
        'installed_at' => 'datetime',
    ];

    /**
     * Bust the enabled/disabled slug caches whenever a package row changes
     * (e.g. the admin flips the `enabled` toggle) so the disable/enable takes
     * effect on the very next request — no manual cache clear or deploy needed.
     */
    protected static function booted(): void
    {
        $forget = fn () => app(PackageRegistry::class)->forgetCache();

        static::saved($forget);
        static::deleted($forget);
    }
}
