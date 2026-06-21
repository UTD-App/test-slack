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

        // Keep only fields the client actually sent; drop null/'' but NOT "0"
        // (a bare array_filter would silently discard gender=0 / female).
        $user->update(array_filter(
            $request->only(['name', 'bio', 'birthday', 'gender']),
            static fn ($v) => $v !== null && $v !== '',
        ));

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

        // Covers: the multi-image profile banner (up to 3). Each entry is either
        // an already-uploaded path/URL string (from /media/upload, the reusable
        // client path) or a raw file uploaded inline. Sending the `covers` key —
        // even an empty array — replaces the stored set (so clearing works);
        // omitting it leaves the existing covers untouched. Mirrors the avatar
        // path so storage stays provider-agnostic.
        $covers = $this->resolveCovers($request);
        if ($covers !== null) {
            $user->profile()->updateOrCreate(['user_id' => $user->id], ['covers' => $covers]);
        }

        return Common::apiResponse(true, 'Profile updated', $user->fresh()->load(['profile', 'country']));
    }

    /**
     * Resolve the incoming `covers` payload into an array of stored paths, or
     * null when the client did not send a `covers` key at all (→ leave the
     * existing covers untouched). An empty array clears the covers. Accepts
     * already-uploaded path/URL strings and/or inline uploaded files; both
     * resolve through the Media seam so storage stays provider-agnostic.
     *
     * @return array<int, string>|null
     */
    protected function resolveCovers(Request $request): ?array
    {
        $sent = $request->hasFile('covers') || $request->exists('covers');
        if (! $sent) {
            return null;
        }

        $files = array_values(array_filter((array) $request->file('covers', [])));
        $strings = array_values(array_filter(
            (array) $request->input('covers', []),
            static fn ($v) => is_string($v) && $v !== '',
        ));

        // Cap the total number of covers (files + already-uploaded strings).
        // The app renders CValidationException as a 422 (a plain Laravel
        // ValidationException would fall through the api Handler to a 500).
        $this->validateCovers(
            ['covers' => array_merge($files, $strings)],
            ['covers' => 'array|max:3'],
        );

        $paths = [];

        foreach ($files as $file) {
            $this->validateCovers(
                ['cover' => $file],
                ['cover' => 'image|mimes:jpeg,jpg,png,webp|max:5120'],
            );
            $paths[] = \App\Facades\Media::upload($file, 'covers')->path;
        }

        foreach ($strings as $value) {
            $this->validateCovers(
                ['cover' => $value],
                ['cover' => 'string|max:2048'],
            );
            $paths[] = $value;
        }

        return array_values($paths);
    }

    /** Validate a small payload, raising the app's 422 exception on failure. */
    protected function validateCovers(array $data, array $rules): void
    {
        $validator = \Illuminate\Support\Facades\Validator::make($data, $rules);
        if ($validator->fails()) {
            throw new \App\Exceptions\CValidationException($validator->errors()->first());
        }
    }

    /**
     * Dedicated avatar upload for the server-driven `core.changeAvatar` action
     * (POST /profile/avatar, field `image`). Stores through the Media seam
     * (provider-agnostic, same as updateProfile) and returns the RESOLVED
     * absolute URL in `data.url`, which the Flutter action writes straight into
     * the user cache so the photo updates in place. Validates via the app's 422
     * convention (a plain $request->validate would 500 on api/* routes).
     */
    public function updateAvatar(Request $request)
    {
        $validator = \Illuminate\Support\Facades\Validator::make(
            ['image' => $request->file('image')],
            ['image' => 'required|image|mimes:jpeg,jpg,png,webp|max:5120'],
        );
        if ($validator->fails()) {
            throw new \App\Exceptions\CValidationException($validator->errors()->first());
        }

        $user = $request->user();
        $path = \App\Facades\Media::upload($request->file('image'), 'avatars')->path;
        $user->profile()->updateOrCreate(['user_id' => $user->id], ['avatar' => $path]);

        return Common::apiResponse(true, 'Avatar updated', [
            'url'  => \App\Facades\Media::url($path),
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
