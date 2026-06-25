<?php

namespace App\Contracts;

/**
 * Optional seam for the social follow graph.
 *
 * The "Following" feed (Moment feed types 3 & 6) shows moments authored by the
 * people the viewer follows. The follow graph lives in the **social** package, so
 * Moment never hard-depends on it: it resolves this contract only when bound. The
 * Base ships NO binding — while `app()->bound(FollowProvider::class)` is false the
 * "following" feeds gracefully fall back to the full feed (current behaviour),
 * exactly as Eagle would show before any follows exist.
 */
interface FollowProvider
{
    /** Ids of the users that $userId follows (empty array if none). */
    public function followingIds(int $userId): array;
}
