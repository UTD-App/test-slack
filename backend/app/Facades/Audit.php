<?php

namespace App\Facades;

use Illuminate\Support\Facades\Facade;

/**
 * Admin audit trail. Record an explicit action:
 *
 *   Audit::log('packages.toggle', $package, ['enabled' => true], 'Disabled gifts');
 *
 * No-ops when no admin is acting, so it is always safe to call. Models that use
 * the {@see \App\Support\Auditable} trait record create/update/delete automatically.
 *
 * @method static \App\Models\AuditLog|null log(string $action, object $subject = null, array $changes = [], ?string $description = null, ?\App\Models\AdminUser $actor = null)
 * @method static \App\Models\AdminUser|null actor()
 *
 * @see \App\Services\AuditLogger
 */
class Audit extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return 'utd.audit';
    }
}
