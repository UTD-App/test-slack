<?php

namespace Utd\Wallet\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

/**
 * Coin ledger row for every wallet movement. Written by DatabaseWallet on each
 * credit/debit. `type` is a CoinTransactionType; `sub_type`/`item_name` add detail
 * (ported from Eagle's user_coin_logs); `reference` links the source row.
 */
class WalletTransaction extends Model
{
    protected $fillable = [
        'wallet_id',
        'user_id',
        'currency',
        'type',
        'sub_type',
        'amount',
        'balance_before',
        'balance_after',
        'item_name',
        'reference_type',
        'reference_id',
        'idempotency_key',
        'meta',
    ];

    protected $casts = [
        'amount'         => 'decimal:2',
        'balance_before' => 'decimal:2',
        'balance_after'  => 'decimal:2',
        'meta'           => 'array',
    ];

    public function wallet(): BelongsTo
    {
        return $this->belongsTo(UserWallet::class, 'wallet_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function reference(): MorphTo
    {
        return $this->morphTo();
    }
}
