<?php

namespace Utd\Reels\Http\Controllers;

use App\Helpers\Common;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Reels\Http\Services\RealsService;
use Utd\Reels\Transformers\RealsResource;

class RealsController extends Controller
{
    public function __construct(public RealsService $realsService) {}

    public function index(Request $request)
    {
        $currentUser = Auth::id();
        // `seed` drives a stable per-refresh random order (see ReelsRepository);
        // 0/absent means no seed → the default chronological feed.
        $seed = $request->integer('seed') ?: null;
        $reals = $this->realsService->getFeed($currentUser, $request->get('filter'), $seed);

        return Common::apiResponse(1, 'success', RealsResource::collection($reals));
    }

    public function getUserReals(Request $request, $user_id = null)
    {
        $currentUser = Auth::id();
        $targetId = $user_id ?? $currentUser;

        if (! User::query()->whereKey($targetId)->exists()) {
            return Common::apiResponse(false, __('reels::messages.user_not_found'));
        }

        $reals = $this->realsService->getUserReals($targetId, $currentUser);

        return Common::apiResponse(true, 'success', RealsResource::collection($reals));
    }

    public function getMyReals()
    {
        $currentUser = Auth::id();
        $reals = $this->realsService->getUserReals($currentUser, $currentUser);

        return Common::apiResponse(true, 'success', RealsResource::collection($reals));
    }

    public function getUserFollowersReals()
    {
        $currentUser = Auth::id();
        $reals = $this->realsService->getFollowersFeed($currentUser);

        return Common::apiResponse(true, 'success', RealsResource::collection($reals));
    }

    public function store(Request $request)
    {
        // Manual validation (the Base renders FormRequest ValidationExceptions as
        // HTTP 500, so packages validate inline and return the standard envelope).
        if (! $request->hasFile('video')) {
            return Common::apiResponse(0, __('reels::messages.empty_content'));
        }

        if (mb_strlen((string) $request->input('description', '')) > 500) {
            return Common::apiResponse(0, __('reels::messages.content_too_long'));
        }

        // categories (interest ids) — optional; must be a list of ints. No
        // exists:interests check yet (no interests catalog in the Base — see NOTES_GAPS).
        $categories = $request->input('categories', []);
        if (! is_array($categories) || array_filter($categories, fn ($c) => ! is_numeric($c))) {
            return Common::apiResponse(0, __('reels::messages.missing_params'));
        }

        $real = $this->realsService->create($request->all(), Auth::id());

        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.try_again'));
        }

        return Common::apiResponse(1, __('reels::messages.success'), new RealsResource($real));
    }

    public function show($real_id)
    {
        $real_id = (int) $real_id;
        if (! $real_id) {
            return Common::apiResponse(false, __('reels::messages.missing_params'));
        }

        $real = $this->realsService->showReal($real_id, Auth::id());
        if (! $real) {
            return Common::apiResponse(false, __('reels::messages.no_real'));
        }

        return Common::apiResponse(true, 'success', new RealsResource($real));
    }

    public function destroy($id)
    {
        $deleted = $this->realsService->delete((int) $id);

        if (! $deleted) {
            return Common::apiResponse(0, __('reels::messages.not_owner'), null, 402);
        }

        return Common::apiResponse(1, __('reels::messages.success'));
    }

    public function update($real_id, Request $request)
    {
        if (mb_strlen((string) $request->input('description', '')) > 500) {
            return Common::apiResponse(0, __('reels::messages.content_too_long'));
        }

        try {
            $result = $this->realsService->update($real_id, $request->all());

            if (! $result) {
                return Common::apiResponse(0, __('reels::messages.try_again'));
            }

            return Common::apiResponse(1, __('reels::messages.success'), new RealsResource($result));
        } catch (\Throwable) {
            return Common::apiResponse(0, __('reels::messages.try_again'));
        }
    }
}
