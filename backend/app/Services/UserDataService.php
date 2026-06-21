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
            'is_online' => $user->isOnline(),
            'last_seen' => $user->online_time?->toIso8601String(),
            'country' => $user->country?->toArray(),
            'profile' => $this->profilePayload($user),
            'stats' => $this->socialCounts($user),
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
            'is_online' => $user->isOnline(),
            'last_seen' => $user->online_time?->toIso8601String(),
            'country' => $user->country?->toArray(),
            'profile' => $this->profilePayload($user),
            'stats' => $this->socialCounts($user),
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

    /**
     * The profile relation as an array, but with gender/birthday sourced from
     * the USER columns (what the profile editor actually writes to) so they
     * always reflect the user even when the legacy profiles.* columns are empty.
     * Falls back to the profile relation's values when the user column is null.
     */
    private function profilePayload(User $user): array
    {
        $profile = $user->profile?->toArray() ?? [];

        $profile['gender'] = $user->gender ?? ($profile['gender'] ?? null);

        $birthday = $user->birthday ?? ($profile['birthday'] ?? null);
        $profile['birthday'] = $birthday
            ? \Illuminate\Support\Carbon::parse($birthday)->toDateString()
            : null;

        return $profile;
    }

    /**
     * Denormalised social counters (kept on the users table). Surfaced so the
     * profile can show a Friends / Following / Followers row without depending
     * on the social package. When that package is installed it can contribute a
     * richer interactive version under its own key.
     */
    private function socialCounts(User $user): array
    {
        return [
            'friends' => (int) ($user->number_of_friends ?? 0),
            'following' => (int) ($user->number_of_followings ?? 0),
            'followers' => (int) ($user->number_of_fans ?? 0),
        ];
    }
}
