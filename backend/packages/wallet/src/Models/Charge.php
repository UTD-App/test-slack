<?php

namespace Utd\Wallet\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/**
 * A manual charge: someone (charger) gave/deducted currency to/from a target.
 * The balance itself moves through the Wallet; this row is the charge-specific
 * history (who, how much, USD value, reason) and links to its ledger row.
 */
class Charge extends Model
{
    protected $fillable = [
        'charger_type',
        'charger_id',
        'target_type',
        'target_id',
        'currency',
        'amount',
        'balance_before',
        'balance_after',
        'usd',
        'is_used_transferred',
        'reason',
        'reason_en',
        'reason_ar',
        'invoice',
        'meta',
        'wallet_transaction_id',
    ];

    protected $casts = [
        'amount'              => 'decimal:2',
        'balance_before'      => 'decimal:2',
        'balance_after'       => 'decimal:2',
        'usd'                 => 'decimal:3',
        'is_used_transferred' => 'boolean',
        'meta'                => 'array',
    ];

    public function charger(): MorphTo
    {
        return $this->morphTo();
    }

    public function target(): MorphTo
    {
        return $this->morphTo();
    }

    public function walletTransaction(): BelongsTo
    {
        return $this->belongsTo(WalletTransaction::class, 'wallet_transaction_id');
    }
}
