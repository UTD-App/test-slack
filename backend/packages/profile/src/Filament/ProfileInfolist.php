<?php

namespace Utd\Profile\Filament;

use App\Contracts\GiftDirectory;
use App\Models\User;
use App\Services\StorageConfigService;
use Filament\Infolists\Components\ViewEntry;
use Filament\Infolists\Infolist;

/**
 * The rich "view a user" profile shown in the admin dashboard, owned by the
 * Profile package. Registered into App\Support\UserProfileInfolistRegistry at
 * boot (gated by the package being enabled), so it AUTOMATICALLY takes over the
 * base UserResource view when the package is installed, and the base falls back
 * to its plain schema when it isn't.
 *
 * PERFORMANCE: the header only pulls the LIGHT, bounded data it actually shows —
 * gift levels + top-N supporters (one indexed query each) via the GiftDirectory
 * contract, and the denormalised social counts + a small friends preview. The
 * heavy per-user lists (gifts received/sent, reels, moments, reports) live in
 * lazy, paginated RelationManager TABS, so opening a whale's profile stays fast.
 */
class ProfileInfolist
{
    /** Build the infolist: a single full-width Blade card with the whole design. */
    public static function build(Infolist $infolist): Infolist
    {
        return $infolist->schema([
            ViewEntry::make('utd_profile')
                ->state(fn (?User $record): array => $record ? self::data($record) : [])
                ->view('profile::user-profile')
                ->columnSpanFull(),
        ]);
    }

    /**
     * Flattened, view-ready data for one user. Image paths are normalised to
     * HOST-RELATIVE `/storage/...` URLs so they load in the admin browser on any
     * host (the stored `10.0.2.2` is emulator-only); external URLs pass through.
     */
    public static function data(User $user): array
    {
        $user->loadMissing(['profile', 'country']);

        $url = static fn (?string $p): ?string => self::webUrl($p);

        // Gifts — via the decoupled contract; only levels + top supporters (light).
        $levels = [];
        $supporters = [];
        if (app()->bound(GiftDirectory::class)) {
            $gd = app(GiftDirectory::class);
            $levels = $gd->levelsFor((int) $user->id);
            $supporters = $gd->topSupporters((int) $user->id);
        }

        // Social — guarded soft dependency. The follower/following/friends/
        // visitors stat cards are OWNED by the Social package: we build them only
        // when that package is installed. Without it there are no such numbers to
        // show, so the whole stats row is omitted (NOT rendered as a row of zeros).
        $statsCards = [];
        $friendsRaw = [];
        if (class_exists(\Utd\Social\Services\SocialService::class)) {
            $svc = app(\Utd\Social\Services\SocialService::class);
            $stats = $svc->statsFor((int) $user->id, null);
            $friendsRaw = $svc->friendsPreview((int) $user->id);
            $statsCards = [
                ['label' => 'followers', 'value' => (int) ($stats['fans_count'] ?? 0)],
                ['label' => 'following', 'value' => (int) ($stats['following_count'] ?? 0)],
                ['label' => 'friends',   'value' => (int) ($stats['friends_count'] ?? 0)],
                ['label' => 'visitors',  'value' => (int) ($stats['visitors_count'] ?? 0)],
            ];
        }

        return [
            'id'       => $user->id,
            'name'     => $user->name,
            'uuid'     => $user->uuid,
            'avatar'   => $url($user->profile?->avatar),
            'covers'   => array_values(array_filter(array_map(
                $url,
                (array) ($user->profile?->covers ?? []),
            ))),
            'country'  => $user->country?->name,
            'flag'     => $url($user->country?->flag),
            'gender'   => (int) ($user->profile?->gender ?? 0),
            'bio'      => $user->bio,
            'online'   => $user->online_time,
            'email'    => $user->email,
            'phone'    => $user->phone,
            'birthday' => optional($user->profile)->birthday,
            'status'   => (bool) $user->status,
            'joined'   => optional($user->created_at)?->format('Y-m-d'),
            'levels'   => [
                'sender'       => $levels['sender_level'] ?? null,
                'receiver'     => $levels['receiver_level'] ?? null,
                'sender_img'   => $url($levels['sender_level_img'] ?? null),
                'receiver_img' => $url($levels['receiver_level_img'] ?? null),
            ],
            'stats' => $statsCards,
            'supporters' => array_map(static fn ($s) => [
                'user_id' => (int) ($s['user_id'] ?? 0),
                'name'    => $s['name'] ?? null,
                'total'   => (int) ($s['total'] ?? 0),
                'avatar'  => $url($s['avatar'] ?? null),
                'url'     => self::profileUrl((int) ($s['user_id'] ?? 0)),
            ], $supporters),
            'friends' => array_map(static fn ($f) => [
                'id'     => (int) ($f['id'] ?? 0),
                'name'   => $f['name'] ?? null,
                'avatar' => $url($f['avatar'] ?? null),
                'url'    => self::profileUrl((int) ($f['id'] ?? 0)),
            ], $friendsRaw),
        ];
    }

    /** Link to a user's own dashboard profile (graceful when outside the panel). */
    private static function profileUrl(int $id): string
    {
        if ($id <= 0) {
            return '#';
        }
        try {
            return \App\Filament\Resources\UserResource::getUrl('view', ['record' => $id]);
        } catch (\Throwable) {
            return '#';
        }
    }

    /** K/M number formatting for big counts (coins, etc.). */
    public static function fmt(int|float|null $n): string
    {
        $n = (int) ($n ?? 0);
        if ($n >= 1_000_000) {
            return round($n / 1_000_000, 1) . 'M';
        }
        if ($n >= 1_000) {
            return round($n / 1_000, 1) . 'K';
        }
        return (string) $n;
    }

    /**
     * Resolve a stored media value to a browser-loadable URL for the admin web.
     * Delegates to the base's shared, driver-aware resolver (absolute cloud URL
     * for GCS/S3; host-relative /storage/… for the local public disk whose host
     * may be the emulator's 10.0.2.2; passthrough for external URLs) so the
     * profile page and the user-index column resolve avatars identically.
     */
    private static function webUrl(?string $path): ?string
    {
        return app(StorageConfigService::class)->webUrl($path);
    }
}
