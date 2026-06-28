<?php

namespace Utd\Reels\Profile;

use App\Contracts\ProfileContributor;
use App\Models\User;
use Utd\Reels\Entities\Real;

/**
 * Contributes the "reels" section (count) to a user's profile. The full list is
 * loaded by the client from the existing GET /api/reals/user/{id}. Registered only
 * when the Reels package is enabled.
 */
class ReelsProfileContributor implements ProfileContributor
{
    public function key(): string
    {
        return 'reels';
    }

    public function contribute(User $target, ?User $viewer): ?array
    {
        return [
            'count' => Real::query()->where('user_id', $target->id)->count(),
        ];
    }
}
