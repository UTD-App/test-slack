<?php

namespace App\Support;

use App\Facades\Audit;
use Illuminate\Support\Collection;

/**
 * Opt-in audit trail for a model. `use Auditable;` and every create / update /
 * delete performed by an admin is recorded (via {@see \App\Services\AuditLogger},
 * which no-ops when no admin is acting — so seeders/jobs stay silent).
 *
 * Customise the ignored attributes per model with a `$auditExclude` array.
 */
trait Auditable
{
    public static function bootAuditable(): void
    {
        static::created(function ($model) {
            $model->recordAudit('created', $model->auditableAttributes($model->getAttributes()));
        });

        static::updated(function ($model) {
            $changes = $model->auditableChanges();
            if ($changes !== []) {
                $model->recordAudit('updated', $changes);
            }
        });

        static::deleted(function ($model) {
            $model->recordAudit('deleted', []);
        });
    }

    protected function recordAudit(string $action, array $changes): void
    {
        Audit::log($action, $this, $changes);
    }

    /** Attributes never written to the trail (secrets + churny timestamps). */
    protected function auditExcluded(): array
    {
        $extra = property_exists($this, 'auditExclude') ? $this->auditExclude : [];

        return array_merge(['password', 'remember_token', 'created_at', 'updated_at'], $extra);
    }

    protected function auditableChanges(): array
    {
        return (new Collection($this->getChanges()))->except($this->auditExcluded())->all();
    }

    protected function auditableAttributes(array $attributes): array
    {
        return (new Collection($attributes))->except($this->auditExcluded())->all();
    }
}
