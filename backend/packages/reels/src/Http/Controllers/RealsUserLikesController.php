<?php

namespace Utd\Reels\Http\Controllers;

use App\Facades\Notifier;
use App\Helpers\Common;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Reels\Entities\Real;
use Utd\Reels\Http\Services\RealLikesService;
use Utd\Reels\Transformers\LikesResource;

class RealsUserLikesController extends Controller
{
    public function __construct(protected RealLikesService $realLikesService) {}

    public function index($real_id)
    {
        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 402);
        }

        $likes = $this->realLikesService->showLikes($real);

        return Common::apiResponse(1, __('reels::messages.success'), LikesResource::collection($likes), 200);
    }

    public function store($real_id, Request $request)
    {
        $user = Auth::user();

        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 402);
        }

        // Facebook-style reaction type; defaults to 'like' (back-compat with the
        // old plain-like client that sends no body).
        $type = (string) $request->input('reaction_type', 'like');
        if (! in_array($type, ['like', 'love', 'haha', 'wow', 'sad', 'angry'], true)) {
            $type = 'like';
        }

        $result = $this->realLikesService->react($real, $user, $type);

        if ($result !== 'removed') {
            $this->notifyOwner($real, $user, 'reels.like');
        }

        return Common::apiResponse(1, __('reels::messages.success'), [], 200);
    }

    public function destroy($real_id, $id)
    {
        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 402);
        }

        // Scope to the caller so a user can only remove THEIR OWN like.
        $this->realLikesService->delete($id, $real, Auth::id());

        return Common::apiResponse(1, __('reels::messages.success'), [], 200);
    }

    /**
     * Notify the reel owner via the high-level Notifier (in-app feed + push +
     * recipient-locale text + preferences). No-op if the notification system
     * isn't installed. Replaces App\Facades\CustomNotification::likeReal().
     */
    protected function notifyOwner(Real $real, $actor, string $typeKey): void
    {
        if (! app()->bound('utd.notifier')) {
            return;
        }

        $owner = User::find($real->user_id);
        if (! $owner || $owner->id === $actor->id) {
            return;
        }

        Notifier::send(
            $owner,
            $typeKey,
            params: ['name' => $actor->name ?? __('reels::messages.someone')],
            data: ['reel_id' => $real->id],
            actor: $actor,
        );
    }
}
