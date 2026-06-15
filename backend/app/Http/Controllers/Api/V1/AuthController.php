<?php

namespace App\Http\Controllers\Api\V1;

use App\Events\DeviceTokenSent;
use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Auth\LoginRequest;
use App\Http\Requests\Api\V1\Auth\RegisterRequest;
use App\Models\DevicesTokenHistory;
use App\Models\User;
use App\Services\UserDataService;
use App\Tik\Services\AuthService;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(private AuthService $authService) {}

    public function register(RegisterRequest $request)
    {
        $deviceToken = $request->input('device_token');

        if (!empty($deviceToken)) {
            try {
                $limit = (int) (Common::getSettingValue('register_account') ?? 3);
                $record = DevicesTokenHistory::where('device_token', $deviceToken)->first();

                if ($record && $record->count >= $limit) {
                    return Common::apiResponse(false, __('max_accounts_reached'), [], 422);
                }
            } catch (\Exception $e) {
                \Log::error('Device token check failed', ['error' => $e->getMessage()]);
            }
        }

        try {
            [$user, $token] = $this->authService->registration($request);
        } catch (\Exception $exception) {
            return Common::apiResponse(false, $exception->getMessage(), null, 422);
        }

        $user->auth_token = $token;

        return Common::apiResponse(
            true,
            __('api_responses.logged'),
            [
                'id' => $user->id,
                'is_first' => (bool) ($user->is_points_first ?? false),
                'auth_token' => $user->auth_token,
            ]
        );
    }

    public function login(LoginRequest $request)
    {
        $fields = [
            'email' => $request['email'],
            'password' => $request['password'],
            'device_token' => $request['device_token'],
            'uuid' => $request['uuid'],
        ];

        return $this->loginWithEmailPassword($fields);
    }

    protected function loginWithEmailPassword($fields)
    {
        try {
            [$user, $token] = $this->authService->loginWithPassword($fields);
        } catch (\Exception $exception) {
            return Common::apiResponse(false, $exception->getMessage(), null, 422);
        }

        try {
            if ($user->device_token) {
                event(new DeviceTokenSent($user->id, $user->device_token));
            }
        } catch (\Exception $e) {
        }

        $user->auth_token = $token;

        return Common::apiResponse(
            true,
            __('api_responses.logged'),
            [
                'id' => $user->id,
                'is_first' => (bool) ($user->is_points_first ?? false),
                'auth_token' => $user->auth_token,
            ]
        );
    }

    public function checkEmail(Request $request)
    {
        $email = $request->input('email');
        if (!$email) {
            return Common::apiResponse(false, 'Email is required', null, 422);
        }

        $exists = User::where('email', $email)->exists();
        return Common::apiResponse(true, '', ['exists' => $exists]);
    }

    public function myData(Request $request)
    {
        $user = $request->user();
        $data = app(UserDataService::class)->aggregateUserData($user);
        return Common::apiResponse(true, '', $data);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $user->update(array_filter($request->only(['name', 'bio', 'birthday', 'gender'])));

        // Avatar: either an already-uploaded path/URL string (from /media/upload,
        // the reusable client path) or a raw file uploaded inline. Both go
        // through / resolve via the Media seam, so storage stays provider-agnostic.
        $avatar = null;
        if ($request->hasFile('avatar')) {
            $request->validate(['avatar' => 'image|mimes:jpeg,jpg,png,webp|max:5120']);
            $avatar = \App\Facades\Media::upload($request->file('avatar'), 'avatars')->path;
        } elseif ($request->filled('avatar')) {
            $request->validate(['avatar' => 'string|max:2048']);
            $avatar = $request->input('avatar');
        }
        if ($avatar !== null) {
            $user->profile()->updateOrCreate(['user_id' => $user->id], ['avatar' => $avatar]);
        }

        return Common::apiResponse(true, 'Profile updated', $user->fresh()->load(['profile', 'country']));
    }

    public function getSettings(Request $request)
    {
        $settings = app(\App\Services\UserSettingService::class)->getAll($request->user());
        return Common::apiResponse(true, '', $settings);
    }

    public function updateSettings(Request $request)
    {
        $settings = $request->validate(['settings' => 'required|array']);
        app(\App\Services\UserSettingService::class)->setBulk($request->user(), $settings['settings']);
        return Common::apiResponse(true, 'Settings updated');
    }

    public function getRoles(Request $request)
    {
        $roles = $request->user()->roles()->pluck('key')->toArray();
        return Common::apiResponse(true, '', $roles);
    }

    public function logout(Request $request)
    {
        $user = $request->user();
        $user->is_logout = true;
        $user->save();
        $request->user()->currentAccessToken()->delete();

        return Common::apiResponse(true, 'Logged out');
    }

    /**
     * Delete the authenticated user's own account: revoke all tokens and
     * soft-delete the user (User uses SoftDeletes, so the row is kept with
     * deleted_at set and can be restored by an admin if needed).
     */
    public function deleteAccount(Request $request)
    {
        $user = $request->user();

        $user->tokens()->delete();
        $user->delete();

        return Common::apiResponse(true, 'Account deleted');
    }
}
