<?php

namespace App\Contracts;

use App\Models\User;

/**
 * Plugin seam for LUCKY gifts. The Gifts core handles normal gifts; when a gift's
 * type is "lucky" it delegates to this resolver IF one is bound. The Base ships NO
 * binding — the `lucky-gift` plugin binds it (probability/multiplier/win logic).
 * Until then, lucky gifts stay disabled.
 *
 * Returns the same envelope as GiftSender::send → ['success','message','data'].
 */
interface LuckyGiftResolver
{
    public function send(User $sender, User $receiver, int $giftId, int $quantity, array $context = []): array;
}
