<?php

namespace Utd\Gifts\Profile;

use App\Contracts\GiftDirectory;
use App\Contracts\ProfileContributor;
use App\Models\User;
use Utd\Gifts\Services\GiftLevelService;

/**
 * Contributes the "received gifts" section to a user's profile. Registered by the
 * Gifts provider only when the package is enabled — so it's absent (no section)
 * when Gifts is off, and appears automatically when it's on.
 */
class GiftsProfileContributor implements ProfileContributor
{
    public function key(): string
    {
        return 'gifts';
    }

    public function contribute(User $target, ?User $viewer): ?array
    {
        if (! app()->bound(GiftDirectory::class)) {
            return null;
        }

        $directory = app(GiftDirectory::class);
        $items     = $directory->receivedBy((int) $target->id);
        $levels    = app(GiftLevelService::class)->statsFor((int) $target->id);

        $section = [
            'count' => (int) array_sum(array_column($items, 'num')),
            'items' => $items,
            // Sender/receiver level badges (icon + number) shown on the profile.
            'sender_level'       => $levels['sender_level'],
            'receiver_level'     => $levels['receiver_level'],
            'sender_level_img'   => $levels['sender_level_img'],
            'receiver_level_img' => $levels['receiver_level_img'],
            // Raw EXP + next-level threshold (lets the app draw a progress bar).
            'sender_exp'              => $levels['sender_exp'],
            'receiver_exp'            => $levels['receiver_exp'],
            'sender_next_threshold'   => $levels['sender_next_threshold'],
            'receiver_next_threshold' => $levels['receiver_next_threshold'],
        ];

        // Visiting-only extras: a user's top supporters and the gifts they've sent.
        // Only computed when looking at someone ELSE's profile (the app shows these
        // on the visited-profile tabs, never on the viewer's own profile).
        if ($viewer === null || $viewer->id !== $target->id) {
            $section['top_supporters'] = $directory->topSupporters((int) $target->id);
            $section['sent']           = $directory->sentBy((int) $target->id);
        }

        return $section;
    }
}
