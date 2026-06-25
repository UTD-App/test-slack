<?php

namespace Utd\Wallet\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A coin purchase via a payment gateway (from Eagle `coin_logs`).
 * status: 0 = pending, 1 = done. On completion it credits the wallet
 * (through the Wallet facade, which writes the wallet_transactions ledger).
 */
class CoinLog extends Model
{
    protected $guarded = [];

    protected $casts = [
        'paid_usd'       => 'float',
        'obtained_coins' => 'integer',
        'status'         => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function coin(): BelongsTo
    {
        return $this->belongsTo(Coin::class, 'coin_id');
    }
}
