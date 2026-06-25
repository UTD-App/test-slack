<?php

namespace App\Contracts;

use App\Models\User;

/**
 * Cross-package gifting primitive.
 *
 * Feature packages (Moment, Reels, Room...) let a user send a gift in their own
 * context WITHOUT depending on the Gifts package directly — they resolve this
 * contract from the container. The Base ships NO default binding: while the Gifts
 * package is not installed, `app()->bound(GiftSender::class)` is false and the
 * gifting feature stays gracefully disabled. Installing the Gifts package binds
 * an implementation, and gifting lights up automatically everywhere.
 */
interface GiftSender
{
    /**
     * Send $quantity of gift #$giftId from $sender to a SINGLE $receiver within a
     * context. Convenience wrapper around {@see sendMany()} for one receiver.
     *
     * @param  array  $context  e.g. ['type' => 'moment', 'id' => 123]
     * @return array  ['success' => bool, 'message' => string, 'data' => mixed]
     */
    public function send(User $sender, User $receiver, int $giftId, int $quantity, array $context = []): array;

    /**
     * Send $quantity of gift #$giftId from $sender to MANY receivers in one call
     * (mirrors Eagle's room/live batch: one debit, one batch id, a gift_log + a
     * GiftSent event PER receiver). The sender is charged for
     * price * quantity * count(receivers).
     *
     * @param  User[]  $receivers  one or more receiver users (non-empty)
     * @param  array   $context    e.g. ['type' => 'room', 'id' => 9, 'room_id' => 9,
     *                             'roomowner_id' => 7, 'pk' => true]. Feature
     *                             packages (Room/Family/Agency…) read these keys off
     *                             the GiftSent event to layer their own effects.
     * @return array  ['success' => bool, 'message' => string, 'data' => mixed]
     */
    public function sendMany(User $sender, array $receivers, int $giftId, int $quantity, array $context = []): array;
}
