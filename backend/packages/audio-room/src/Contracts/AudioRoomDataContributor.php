<?php

namespace Utd\AudioRoom\Contracts;

use App\Models\User;
use App\Contracts\UserDataContributor;
use Utd\AudioRoom\Entities\Room;

class AudioRoomDataContributor implements UserDataContributor
{
    public function getKey(): string
    {
        return 'audio_room';
    }

    public function getUserData(User $user): ?array
    {
        $room = Room::where('user_id', $user->id)->where('type', 'audio')->first();

        return [
            'has_room' => $room !== null,
            'room_id' => $room?->id,
            'room_name' => $room?->room_name,
        ];
    }
}
