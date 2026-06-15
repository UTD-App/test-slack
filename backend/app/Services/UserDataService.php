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

    /**
     * Public, viewer-safe core identity for a user as seen by OTHERS (profiles,
     * listings, search). Deliberately omits private fields (email, phone,
     * firebase_uuid, notification_id, settings) that {@see aggregateUserData}
     * returns for the authenticated user's own /api/my-data. Feature-package
     * sections are NOT added here — those are merged by the Profile package via
     * {@see ProfileContributorRegistry}, so each section is package-gated.
     */
    public function publicData(User $user): array
    {
        $user->load(['country', 'profile', 'roles']);

        return [
            'id' => $user->id,
            'name' => $user->name,
            'uuid' => $user->uuid,
            'bio' => $user->bio,
            'online_time' => $user->online_time,
            'country' => $user->country?->toArray(),
            'profile' => $user->profile?->toArray(),
            'roles' => $user->roles->pluck('key')->values()->toArray(),
        ];
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
