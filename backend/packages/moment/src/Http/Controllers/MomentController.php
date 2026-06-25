<?php

namespace Utd\Moment\Http\Controllers;

use App\Helpers\Common;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Moment\Http\Services\MomentService;
use Utd\Moment\Transformers\MomentResource;

class MomentController extends Controller
{
    public function __construct(public MomentService $momentService) {}

    public function index(Request $request)
    {
        $type = $request->type;
        $page = $request->get('page', 1);
        $userId = $request->user_id;
        $currentUser = Auth::id();

        // When a user_id is given the feed is scoped to that user's own posts
        // (the profile "My Posts" view), regardless of the list `type` — type 4
        // (getAllMoments) ignores user_id and would return the whole feed.
        if ($userId) {
            $type = 1;
        }

        $data = $this->momentService->getMomentsByType($type, $userId, $page, $currentUser);

        if (! $data) {
            return Common::apiResponse(1, __('moment::messages.invalid_type'), '', 200);
        }

        return Common::apiResponse(1, '', MomentResource::collection($data), 200);
    }

    /** A specific user's moments (for the profile package). */
    public function userMoments(Request $request, $user_id)
    {
        $page = $request->get('page', 1);
        $data = $this->momentService->getMomentsByType(1, $user_id, $page, Auth::id());

        return Common::apiResponse(1, '', MomentResource::collection($data ?: []), 200);
    }

    public function store(Request $request)
    {
        $contacts = $request->contacts ?? '';

        $result = $this->momentService->createMoment($contacts, $request);

        return Common::apiResponse($result['success'], $result['message']);
    }

    public function show(Request $request, $id)
    {
        $userId = Auth::id();

        $result = $this->momentService->getMoment($id, $userId);

        if (! $result['success']) {
            return Common::apiResponse(0, $result['message'], null, $result['status']);
        }

        return Common::apiResponse(1, $result['message'], new MomentResource($result['data']), $result['status']);
    }

    public function destroy($id)
    {
        $result = $this->momentService->deleteMomentById($id, Auth::id());

        return Common::apiResponse($result['success'] ? 1 : 0, $result['message'], null, $result['status']);
    }

    // NOTE(gap): Eagle's Encore-based destroy_dash() is replaced by the Filament
    // MomentResource (Utd\Moment\Filament).
}
