<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\UserDataService;
use Illuminate\Http\Request;

/**
 * User-facing user lookups (search, …).
 *
 * GET /api/users/search?q=<term>
 *   Find other active users by UID (`uuid`) or name. Used by the home-page
 *   search action. Returns a compact, viewer-safe shape (no email/phone) so it
 *   can be shown in a list directly — same envelope as PresenceController.
 *
 * GET /api/users/{id}
 *   Public, viewer-safe profile data for a single user. Always available in the
 *   base (NOT gated by the Profile package), so the app can render a basic
 *   profile fallback for any user even when the rich Profile package isn't
 *   installed. Returns the same core shape the Profile package builds, minus its
 *   package-contributed sections.
 */
class UserController extends Controller
{
    /** Max results returned per query (keeps the response small + cheap). */
    private const LIMIT = 30;

    public function search(Request $request)
    {
        $term = trim((string) $request->query('q', ''));

        // Empty query → empty result (no 422); the client treats it as "idle".
        if ($term === '') {
            return Common::apiResponse(true, '', []);
        }

        $me = $request->user()->id;

        $users = User::query()
            ->where('status', true)
            ->where('id', '!=', $me)
            ->where(function ($query) use ($term) {
                $query->where('uuid', 'like', "%{$term}%")
                    ->orWhere('name', 'like', "%{$term}%");
            })
            ->with('profile')
            ->orderBy('name')
            ->limit(self::LIMIT)
            ->get();

        $data = $users->map(fn (User $user) => [
            'id'        => $user->id,
            'name'      => $user->name,
            'uuid'      => $user->uuid,
            'image'     => $user->profile?->image,
            'is_online' => $user->isOnline(),
        ])->values();

        return Common::apiResponse(true, '', $data);
    }

    /**
     * Public profile data for a single user (base fallback when the Profile
     * package is absent). Viewer-safe — no email/phone/private fields.
     */
    public function show(Request $request, int $id)
    {
        $user = User::find($id);

        if (!$user || !$user->status) {
            return Common::apiResponse(false, __('messages.user_not_found'), null, 404);
        }

        $data = app(UserDataService::class)->publicData($user);
        $data['is_me'] = $request->user()?->id === $user->id;

        return Common::apiResponse(true, '', $data);
    }
}
