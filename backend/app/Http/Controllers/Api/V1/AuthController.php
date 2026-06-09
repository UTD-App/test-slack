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

        $data = $request->only(['name', 'bio', 'birthday', 'gender']);
        $user->update(array_filter($data));

        return Common::apiResponse(true, 'Profile updated', $user->fresh());
    }

    /**
     * تغيير صورة الملف الشخصي (image picker من التطبيق).
     * بيستقبل الصورة، يخزّنها على القرص العام، ويحفظ URL مطلق في users.img
     * (نفس الحقل اللي الـ chat بيعرض منه) عشان يظهر في كل مكان فورًا. الـ URL
     * مبني من host الطلب — فبيشتغل على الجهاز مهما كان APP_URL.
     */
    public function updateAvatar(Request $request)
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,jpg,png,webp|max:5120',
        ]);

        $user = $request->user();

        $path = $request->file('image')->store('avatars', 'public');
        $url  = $request->getSchemeAndHttpHost() . \Illuminate\Support\Facades\Storage::url($path);

        $user->img = $url;
        $user->save();

        return Common::apiResponse(true, 'Avatar updated', [
            'url'  => $url,
            'user' => app(UserDataService::class)->aggregateUserData($user->fresh()),
        ]);
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
}
