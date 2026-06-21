<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * One recorded admin action (panel CRUD or an explicit {@see \App\Facades\Audit}::log
 * call). Rows are only written when a human admin is acting — system/seed/CLI
 * writes are intentionally NOT audited (see {@see \App\Services\AuditLogger}).
 */
class AuditLog extends Model
{
    protected $guarded = [];

    protected $casts = [
        'changes' => 'array',
    ];

    public function adminUser()
    {
        return $this->belongsTo(AdminUser::class);
    }

    public function auditable()
    {
        return $this->morphTo();
    }
}
