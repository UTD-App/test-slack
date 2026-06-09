<?php

namespace App\Tik\Services;

use App\Exceptions\CValidationException;
use App\Helpers\Common;
use App\Models\Country;
use App\Models\DevicesTokenHistory;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthService
{
    public function registration($request)
    {
        $email = $request->email;

        if (User::where('email', $email)->exists()) {
            throw new \Exception('already exists');
        }

        $trashedUser = User::withTrashed()->where('email', $email)->first();

        DB::beginTransaction();
        try {
            $countryId = null;
            $iso = $request->iso;

            if ($trashedUser) {
                $trashedUser->restore();
                $trashedUser->password = $request->password;
                $user = $trashedUser;
            } else {
                $data = [
                    'email' => $email,
                    'firebase_uuid' => $request->uuid,
                    'password' => $request->password,
                    'status' => 1,
                ];

                if ($iso) {
                    $country = Country::where('iso', strtoupper($iso))->first();
                    if ($country) {
                        $countryId = $country->id;
                    }
                }

                if ($countryId) {
                    $data['country_id'] = $countryId;
                }

                if (!empty($request['device_token'])) {
                    $this->checkDeviceRegistrationLimit($request['device_token']);
                }

                $user = User::create($data);
            }

            $user->is_points_first = 1;
            $user->save();

            $token = $user->createToken('api_token')->plainTextToken;

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }

        return [$user, $token];
    }

    public function loginWithPassword($request)
    {
        $user = User::where('email', $request['email'])->first();

        if (!$user || !Hash::check($request['password'], $user->password)) {
            throw new \Exception('credentials does`t match');
        }

        $deviceToken = $request['device_token'] ?? null;

        if ($deviceToken) {
            $this->checkDeviceLoginLimit($user->id, $deviceToken);
            $user->device_token = $deviceToken;
            $user->save();
        }

        if ($user->status != 1) {
            throw new \Exception('you are blocked');
        }

        $token = $user->createToken('api_token')->plainTextToken;
        $user->is_logout = false;
        $user->save();

        return [$user, $token];
    }

    private function checkDeviceRegistrationLimit(string $deviceToken): void
    {
        $limit = (int) (Common::getSettingValue('register_account') ?? 3);

        $count = User::where('device_token', $deviceToken)
            ->where('device_token', '!=', '')
            ->whereNotNull('device_token')
            ->count();

        if ($count >= $limit) {
            throw new CValidationException(__('max_accounts_reached'));
        }

        $record = DevicesTokenHistory::where('device_token', $deviceToken)->first();

        if ($record) {
            $record->increment('count');
        } else {
            DevicesTokenHistory::create(['device_token' => $deviceToken, 'count' => 1]);
        }
    }

    private function checkDeviceLoginLimit(int $userId, string $deviceToken): void
    {
        $limit = (int) (Common::getSettingValue('register_account') ?? 3);

        $count = User::where('device_token', $deviceToken)
            ->where('device_token', '!=', '')
            ->whereNotNull('device_token')
            ->where('id', '!=', $userId)
            ->count();

        if ($count >= $limit) {
            throw new CValidationException(__('max_accounts_reached'));
        }
    }
}
