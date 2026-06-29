<?php

namespace Utd\Gifts\Listeners;

use App\Contracts\RoomOwnerResolver;
use App\Events\Gifts\GiftSent;
use App\Facades\Wallet;
use App\Models\User;
use Utd\Gifts\Support\GiftSettings;

/**
 * Credits the room owner their cut (Eagle's `roomowner_obtain`) when a gift is
 * sent inside a room — i.e. the GiftSent context carries a `roomowner_id`
 * (set by POST /api/gifts/send with owner_id). Moment/Reel gifts have no
 * roomowner_id, so this is a no-op for them.
 *
 * The cut is the earn currency (diamonds) = gift value × rate. The rate defaults
 * to 0.03 (3%) and is ADMIN-TUNABLE via the gift_settings key `room_owner_rate`
 * (falls back to config gifts.room_owner_rate). A dedicated Room/Agency package
 * can take this over later by unbinding this listener — it lives here for now so
 * room gifting is functional out of the box.
 */
class CreditRoomOwnerOnGiftSent
{
    public function handle(GiftSent $event): void
    {
        $roomId = (int) ($event->context['room_id'] ?? 0);
        if ($roomId <= 0) {
            return; // not a room gift → nothing to do
        }

        // Resolve the owner from the room itself, NEVER the client-supplied
        // roomowner_id (which a sender could spoof to steal the cut). Without a
        // room package bound to resolve it, pay nobody.
        if (! app()->bound(RoomOwnerResolver::class)) {
            return;
        }

        $ownerId = (int) (app(RoomOwnerResolver::class)->ownerId($roomId) ?? 0);
        if ($ownerId <= 0) {
            return;
        }

        // Don't pay the owner for gifting themselves or receiving the gift.
        if ($ownerId === (int) $event->sender->getKey() || $ownerId === (int) $event->receiver->getKey()) {
            return;
        }

        if (! Wallet::isAvailable()) {
            return;
        }

        $rate   = GiftSettings::float('room_owner_rate', (float) config('gifts.room_owner_rate', 0.03));
        $amount = round($event->total * $rate, 2);
        if ($amount <= 0) {
            return;
        }

        $owner = User::find($ownerId);
        if (! $owner) {
            return;
        }

        Wallet::credit(
            $owner,
            (string) config('gifts.earn_currency', 'diamonds'),
            $amount,
            'gift_room_owner',
            [
                'gift_id'     => $event->giftId,
                'sender_id'   => $event->sender->getKey(),
                'receiver_id' => $event->receiver->getKey(),
                'room_id'     => $event->context['room_id'] ?? null,
                'batch_id'    => $event->context['batch_id'] ?? null,
                'rate'        => $rate,
            ],
        );
    }
}
