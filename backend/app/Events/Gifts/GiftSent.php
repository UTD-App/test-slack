<?php

namespace App\Events\Gifts;

use App\Models\User;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Fired after a gift is successfully sent. Other packages listen WITHOUT depending
 * on the Gifts package: Agency (diamond split / room-owner & agency cut), Levels
 * (sender/receiver level-up), Ranking (gift rankings), Family… all hook here.
 *
 * `$giftId` (not the Gift model) keeps the Base decoupled from the Gifts package.
 * `$total` = coins spent by sender; `$earned` = diamonds credited to receiver.
 */
class GiftSent
{
    use Dispatchable;

    public function __construct(
        public readonly User $sender,
        public readonly User $receiver,
        public readonly int $giftId,
        public readonly int $quantity,
        public readonly float $total,
        public readonly float $earned,
        public readonly array $context = [],
    ) {
    }
}
