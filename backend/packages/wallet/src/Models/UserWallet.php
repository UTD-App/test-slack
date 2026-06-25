<?php

namespace Utd\Wallet\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * One wallet = one (user, currency) balance. Ships coins + dollar; extensible
 * to any currency by adding a row. available = balance - held.
 */
class UserWallet extends Model
{
    // balance/held are deliberately NOT mass-assignable — they may only be moved
    // through DatabaseWallet (row-locked, ledgered). Keeps a stray
    // ->update($request->all()) from ever letting a user set their own balance.
    protected $fillable = [
        'user_id',
        'currency',
    ];

    protected $casts = [
        'balance' => 'decimal:2',
        'held'    => 'decimal:2',
    ];

    public function getAvailableAttribute(): float
    {
        return (float) $this->balance - (float) $this->held;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(WalletTransaction::class, 'wallet_id')->latest();
    }
}
