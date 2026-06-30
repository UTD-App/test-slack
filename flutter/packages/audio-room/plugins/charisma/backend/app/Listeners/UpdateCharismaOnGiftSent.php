<?php

namespace App\Listeners;

use App\Events\Gifts\GiftSent;
use App\Models\CharismaRoomData;
use App\Models\Room;

class UpdateCharismaOnGiftSent
{
    public function handle(GiftSent $event): void
    {
        $roomId = (int) ($event->context['room_id'] ?? 0);
        if ($roomId <= 0) {
            return;
        }

        $room = Room::find($roomId);
        if (! $room || ! $room->charizma_status) {
            return;
        }

        $receiverId = (int) $event->receiver->getKey();

        $row = CharismaRoomData::firstOrCreate(
            ['room_id' => $roomId, 'user_id' => $receiverId],
            ['total' => 0],
        );

        $row->increment('total', $event->total);
    }
}
