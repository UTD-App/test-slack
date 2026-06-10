<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RoomBoomGift extends Model
{
    protected $fillable = ['total_room_gift_id', 'user_id', 'price', 'room_boom_level', 'start_boom_ranking'];
}
