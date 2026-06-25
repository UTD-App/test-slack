<?php

namespace App\Contracts;

use App\Models\User;

/**
 * Plugin seam for the BAG / BACKPACK spend source.
 *
 * Normally a gift is paid for in coins via the Wallet. When a send is made with
 * context `['source' => 'bag']`, the Gifts core does NOT touch the wallet — it
 * delegates the debit to whoever binds this contract (the future `backpack`
 * plugin, which owns the `user_gifts` inventory table). The Base ships NO binding:
 * while it is unbound, `app()->bound(GiftBagProvider::class)` is false and bag
 * sends fail gracefully ("bag not installed") — coin sends keep working.
 *
 * The credit to the receiver, the gift_log row and the GiftSent event are still
 * handled by the Gifts core exactly as for a coin send.
 */
interface GiftBagProvider
{
    /** Does $user own at least $quantity of gift #$giftId in their (non-expired) bag? */
    public function canAfford(User $user, int $giftId, int $quantity): bool;

    /**
     * Remove $quantity of gift #$giftId from $user's bag. Runs inside the Gifts
     * send transaction; throw to abort the whole send.
     *
     * @return mixed an optional reference/id for the debit (stored on the gift_log)
     */
    public function debit(User $user, int $giftId, int $quantity, array $meta = []): mixed;
}
