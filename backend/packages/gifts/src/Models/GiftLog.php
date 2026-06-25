<?php

namespace Utd\Gifts\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GiftLog extends Model
{
    protected $fillable = [
        'gift_id', 'gift_name', 'sender_id', 'receiver_id', 'gift_num',
        'unit_price', 'total_price', 'spend_currency', 'earn_currency', 'receiver_earned',
        'context_type', 'context_id', 'wallet_debit_tx_id', 'wallet_credit_tx_id',
        'batch_id', 'source', 'is_lucky', 'meta',
    ];

    protected $casts = [
        'gift_num'        => 'integer',
        'unit_price'      => 'decimal:2',
        'total_price'     => 'decimal:2',
        'receiver_earned' => 'decimal:2',
        'is_lucky'        => 'boolean',
        'meta'            => 'array',
    ];

    public function gift(): BelongsTo
    {
        return $this->belongsTo(Gift::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function receiver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }
}
