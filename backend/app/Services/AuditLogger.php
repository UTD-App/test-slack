<?php

namespace App\Services;

use App\Models\AdminUser;
use App\Models\AuditLog;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Request;

/**
 * Records admin actions to the audit trail. Bound as a singleton and exposed via
 * the {@see \App\Facades\Audit} facade ('utd.audit').
 *
 * Design choice: ONLY actions performed by an authenticated AdminUser are stored.
 * Seeders, queue jobs, `utd:sync-packages` and unauthenticated API traffic resolve
 * to no actor, so {@see log()} no-ops — keeping the trail focused on accountable,
 * human admin activity (and avoiding noise on every boot/seed).
 */
class AuditLogger
{
    /** Resolve the acting admin, if any. Only AdminUser instances count. */
    public function actor(): ?AdminUser
    {
        foreach (['admin', 'web'] as $guard) {
            try {
                $user = Auth::guard($guard)->user();
            } catch (\Throwable) {
                $user = null;
            }
            if ($user instanceof AdminUser) {
                return $user;
            }
        }

        $user = Auth::user();

        return $user instanceof AdminUser ? $user : null;
    }

    /**
     * Record an action. Returns null (no-op) when no admin actor is present.
     *
     * @param  object|null  $subject  the model the action targets, if any
     * @param  array  $changes  changed/created attributes worth keeping
     */
    public function log(string $action, $subject = null, array $changes = [], ?string $description = null, ?AdminUser $actor = null): ?AuditLog
    {
        $actor ??= $this->actor();
        if (! $actor) {
            return null;
        }

        return AuditLog::create([
            'admin_user_id'  => $actor->getKey(),
            'action'         => $action,
            'auditable_type' => is_object($subject) ? get_class($subject) : null,
            'auditable_id'   => is_object($subject) && isset($subject->id) ? $subject->id : null,
            'description'    => $description,
            'changes'        => $changes !== [] ? $changes : null,
            'ip'             => $this->ip(),
            'user_agent'     => $this->userAgent(),
        ]);
    }

    protected function ip(): ?string
    {
        try {
            return Request::ip();
        } catch (\Throwable) {
            return null;
        }
    }

    protected function userAgent(): ?string
    {
        try {
            $ua = (string) Request::userAgent();
        } catch (\Throwable) {
            return null;
        }

        return $ua !== '' ? substr($ua, 0, 512) : null;
    }
}
