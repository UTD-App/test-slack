<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserSetting;

class UserSettingService
{
    public function get(User $user, string $key, $default = null)
    {
        $setting = UserSetting::where('user_id', $user->id)
            ->where('key', $key)
            ->first();

        if (!$setting) {
            return $default;
        }

        $decoded = json_decode($setting->value, true);
        return $decoded === null && $setting->value !== 'null'
            ? $setting->value
            : $decoded;
    }

    public function set(User $user, string $key, $value): void
    {
        $storedValue = is_string($value) ? $value : json_encode($value);

        UserSetting::updateOrCreate(
            ['user_id' => $user->id, 'key' => $key],
            ['value' => $storedValue],
        );
    }

    public function getAll(User $user): array
    {
        return UserSetting::where('user_id', $user->id)
            ->pluck('value', 'key')
            ->map(function ($value) {
                $decoded = json_decode($value, true);
                return $decoded === null && $value !== 'null' ? $value : $decoded;
            })
            ->toArray();
    }

    public function setBulk(User $user, array $settings): void
    {
        foreach ($settings as $key => $value) {
            $this->set($user, $key, $value);
        }
    }
}
