<?php

namespace App\Contracts;

/**
 * Optional read-side companion to {@see GiftSender}: lets a feature package
 * (Moment, Reels…) show the gifts received in one of its contexts WITHOUT
 * depending on the Gifts package. The Base ships NO default binding; the Gifts
 * package binds it. Consumers check `app()->bound(GiftDirectory::class)` first.
 *
 * `$type`/`$id` identify the context, e.g. ('moment', 123).
 */
interface GiftDirectory
{
    /** Gifts received in a context, grouped & summed: [['gift_id','name','img','num'], …]. */
    public function giftsFor(string $type, int $id): array;

    /** Who gifted in a context: [['user' => ['id','name'], 'num' => int], …]. */
    public function giftersFor(string $type, int $id): array;

    /** Who received gifts in a context: [['user' => ['id','name','avatar'], 'num' => int], …]. */
    public function receiversFor(string $type, int $id): array;

    /** Total number of gifts received in a context. */
    public function countFor(string $type, int $id): int;

    /** Total coins spent on gifts in a context (sum of gift_logs.total_price). */
    public function coinsFor(string $type, int $id): float;

    /** Gifts a user has received (any context), grouped & summed: [['gift_id','name','img','num'], …]. */
    public function receivedBy(int $userId): array;

    /** Gifts a user has sent (any context), grouped & summed: [['gift_id','name','img','num'], …]. */
    public function sentBy(int $userId): array;

    /** A user's top supporters by coins spent gifting them: [['user_id','name','uuid','avatar','total','gifts'], …]. */
    public function topSupporters(int $userId, int $limit = 6): array;

    /** A user's sender/receiver gift LEVEL badges (level numbers + icon URLs). */
    public function levelsFor(int $userId): array;
}
