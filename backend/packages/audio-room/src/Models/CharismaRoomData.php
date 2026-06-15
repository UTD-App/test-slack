<?php

namespace Utd\AudioRoom\Models;

use App\Models\User;
use Utd\AudioRoom\Entities\Room;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CharismaRoomData extends Model
{
    protected $table = 'charisma_room_data';

    protected $fillable = ['user_id', 'total', 'room_id'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }
}
