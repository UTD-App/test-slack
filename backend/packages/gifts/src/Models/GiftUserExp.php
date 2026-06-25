<?php

namespace Utd\Gifts\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * A user's accumulated gift EXP (sender + receiver). Source of truth for levels;
 * grown atomically on every gift send (see GiftLevelService::addExp). The level
 * itself is NOT stored here — it is derived from the exp on read.
 */
class GiftUserExp extends Model
{
    protected $table = 'gift_user_exp';

    protected $primaryKey = 'user_id';

    public $incrementing = false;

    protected $keyType = 'int';

    protected $fillable = ['user_id', 'sender_exp', 'receiver_exp'];

    protected $casts = [
        'user_id'      => 'integer',
        'sender_exp'   => 'integer',
        'receiver_exp' => 'integer',
    ];
}
