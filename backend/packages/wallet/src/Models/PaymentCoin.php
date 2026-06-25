<?php

namespace Utd\Wallet\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A coin payment package group (e.g. card / wallet / gateway) within a
 * `package_type` (user | shipping_agency). Groups the purchasable Coin packages.
 */
class PaymentCoin extends Model
{
    protected $guarded = [];

    protected $casts = [
        'status' => 'boolean',
    ];

    public function coins(): HasMany
    {
        return $this->hasMany(Coin::class, 'payment_gateway_id');
    }

    public function scopeActive($query)
    {
        return $query->where('status', true);
    }
}
