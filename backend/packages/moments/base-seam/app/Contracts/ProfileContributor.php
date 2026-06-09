<?php

namespace App\Contracts;

use App\Models\User;

/**
 * Lets a feature package (gifts, moment, reels… later follow, vip, family…) add a
 * SECTION to a user's profile WITHOUT the Profile package depending on it. Each
 * package registers a contributor in its provider boot() (gated by isEnabled);
 * the Profile package merges them. A package that isn't installed simply doesn't
 * register — its section is absent and the profile still works. Installing it
 * later makes the section appear automatically, with NO change to the Profile package.
 */
interface ProfileContributor
{
    /** The section key in the profile payload, e.g. 'gifts', 'moments', 'follow'. */
    public function key(): string;

    /**
     * Build this contributor's section for $target's profile as seen by $viewer
     * (viewer is null for unauthenticated/system reads). Return null to omit.
     * e.g. ['count' => 12, 'items' => [...]].
     */
    public function contribute(User $target, ?User $viewer): ?array;
}
