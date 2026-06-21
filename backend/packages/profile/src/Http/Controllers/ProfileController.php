<?php

namespace Utd\Profile\Http\Controllers;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\ProfileContributorRegistry;
use App\Services\UserDataService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;

class ProfileController extends Controller
{
    public function show(int $id): JsonResponse
    {
        $user = User::with(['country', 'profile'])->find($id);

        if (!$user) {
            return Common::apiResponse(false, 'User not found', null, 404);
        }

        $viewer = Auth::user();

        // Public, viewer-safe core identity (no private fields).
        $data = app(UserDataService::class)->publicData($user);

        // Merge one section per ENABLED feature package, each under its own key
        // (gifts now; wallet/follow/vip/family… appear automatically when installed).
        // Core stays authoritative — sections use distinct keys.
        foreach (app(ProfileContributorRegistry::class)->aggregate($user, $viewer) as $key => $section) {
            $data[$key] = $section;
        }

        $data['is_me'] = $viewer?->id === $user->id;

        return Common::apiResponse(true, '', $data);
    }
}
