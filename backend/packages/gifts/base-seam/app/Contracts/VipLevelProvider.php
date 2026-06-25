<?php

namespace App\Contracts;

use App\Models\User;

/**
 * Optional seam for the VIP-level gate on gifts.
 *
 * Some gifts require a minimum VIP level (`gifts.vip_level`). The Gifts core only
 * enforces this when a VIP provider is bound (the future `vip` package binds it).
 * The Base ships NO binding: while `app()->bound(VipLevelProvider::class)` is false
 * the gate is skipped and every user may send any gift — gifting never breaks just
 * because VIP isn't installed.
 */
interface VipLevelProvider
{
    /** Current VIP level of $user (0 = none). */
    public function levelFor(User $user): int;
}
