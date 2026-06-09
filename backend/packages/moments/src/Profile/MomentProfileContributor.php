<?php

namespace Utd\Moment\Profile;

use App\Contracts\ProfileContributor;
use App\Models\User;
use Utd\Moment\Entities\Moment;

/**
 * Contributes the "moments" section (count) to a user's profile. The full list is
 * loaded by the client from GET /api/moment/user/{id}. Registered only when the
 * Moment package is enabled.
 */
class MomentProfileContributor implements ProfileContributor
{
    public function key(): string
    {
        return 'moments';
    }

    public function contribute(User $target, ?User $viewer): ?array
    {
        return [
            'count' => Moment::query()->where('user_id', $target->id)->count(),
        ];
    }
}
