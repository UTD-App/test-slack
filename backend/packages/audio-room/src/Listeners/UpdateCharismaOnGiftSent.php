<?php

namespace Utd\AudioRoom\Listeners;

use App\Events\Gifts\GiftSent;
use Utd\AudioRoom\Entities\Room;
use Utd\AudioRoom\Models\CharismaRoomData;

/**
 * Increments the receiver's charisma total when a gift is sent inside a room
 * that has charisma active. The Flutter client broadcasts the updated totals
 * via RTM after the gift send completes — this listener only persists the change.
 */
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
