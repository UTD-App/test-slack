<?php

namespace App\Contracts;

/**
 * Resolves the trusted owner of a room from its id.
 *
 * The Gifts package credits a room owner their cut when a gift is sent in a room.
 * It must NOT trust a client-supplied owner id (an attacker could redirect the
 * cut to themselves), so it resolves the owner through this seam instead. A room
 * package (e.g. Audio Room) binds an implementation that reads the owner from its
 * own `rooms` table. While no room package is installed the contract is unbound
 * and the room-owner cut is simply skipped.
 */
interface RoomOwnerResolver
{
    /** The user id that owns the given room, or null if unknown. */
    public function ownerId(int $roomId): ?int;
}
