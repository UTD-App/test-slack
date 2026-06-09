<?php

namespace App\Services;

use App\Contracts\UserDataContributor;
use App\Models\User;

class UserDataService
{
    protected array $contributors = [];

    public function register(UserDataContributor $contributor): void
    {
        $this->contributors[$contributor->getKey()] = $contributor;
    }

    public function aggregateUserData(User $user): array
    {
        $user->load(['country', 'profile', 'roles']);

        $data = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'uuid' => $user->uuid,
            'firebase_uuid' => $user->firebase_uuid,
            'bio' => $user->bio,
            // صورة المستخدم كـ URL جاهز للعرض (نفس منطق البحث: img ثم avatar) — عشان
            // مصدر core.currentUser في فلاتر يحلّ الـ avatar binding على شاشة profile.
            'avatar' => $user->img ?: $user->avatar,
            'notification_id' => $user->notification_id,
            'is_first' => (bool) ($user->is_points_first ?? false),
            'online_time' => $user->online_time,
            'country' => $user->country?->toArray(),
            'profile' => $user->profile?->toArray(),
            'roles' => $user->roles->pluck('key')->values()->toArray(),
            'settings' => app(UserSettingService::class)->getAll($user),
        ];

        foreach ($this->contributors as $key => $contributor) {
            $contributed = $contributor->getUserData($user);
            if ($contributed !== null) {
                $data[$key] = $contributed;
            }
        }

        return $data;
    }
}
