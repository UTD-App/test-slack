<?php

namespace Utd\Wallet\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A purchasable coin package: pay `usd` -> get `coin` (+ first-charge / promo bonus).
 * Grouped under a PaymentCoin via `payment_gateway_id`.
 */
class Coin extends Model
{
    use SoftDeletes;

    protected $guarded = [];

    protected $casts = [
        'usd'               => 'float',
        'coin'              => 'integer',
        'first_charge_coin' => 'integer',
        'extra_value'       => 'integer',
        'status'            => 'integer',
    ];

    public function paymentCoin(): BelongsTo
    {
        return $this->belongsTo(PaymentCoin::class, 'payment_gateway_id');
    }

    public function logs(): HasMany
    {
        return $this->hasMany(CoinLog::class, 'coin_id');
    }
}
