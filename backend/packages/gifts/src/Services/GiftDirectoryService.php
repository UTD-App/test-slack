<?php

namespace Utd\Gifts\Services;

use App\Contracts\GiftDirectory;
use App\Models\User;
use Utd\Gifts\Models\GiftLog;
use Utd\Gifts\Services\GiftLevelService;
use Utd\Gifts\Support\Media;

/**
 * Read-side aggregation over gift_logs by context (e.g. a moment). Lets Moment show
 * "gifts on this post" and "who gifted" without depending on the Gifts package.
 */
class GiftDirectoryService implements GiftDirectory
{
    public function giftsFor(string $type, int $id): array
    {
        return GiftLog::query()
            ->where('context_type', $type)
            ->where('context_id', $id)
            ->leftJoin('gifts', 'gifts.id', '=', 'gift_logs.gift_id')
            ->selectRaw('gift_logs.gift_id, gifts.img as img, MAX(gift_logs.gift_name) as name, SUM(gift_logs.gift_num) as num')
            ->groupBy('gift_logs.gift_id', 'gifts.img')
            ->orderByDesc('num')
            ->get()
            ->map(fn ($r) => [
                'gift_id' => (int) $r->gift_id,
                'name'    => $r->name,
                'img'     => Media::url($r->img),
                'num'     => (int) $r->num,
            ])
            ->all();
    }

    public function giftersFor(string $type, int $id): array
    {
        $rows = GiftLog::query()
            ->where('context_type', $type)
            ->where('context_id', $id)
            ->selectRaw('sender_id, SUM(gift_num) as num')
            ->groupBy('sender_id')
            ->orderByDesc('num')
            ->get();

        $users = User::query()
            ->whereIn('id', $rows->pluck('sender_id'))
            ->get(['id', 'name', 'uuid'])
            ->keyBy('id');

        return $rows->map(function ($r) use ($users) {
            $user = $users->get($r->sender_id);

            return [
                'user' => [
                    'id'     => (int) $r->sender_id,
                    'name'   => $user?->name,
                    'avatar' => Media::url($user?->avatar),
                ],
                'num' => (int) $r->num,
            ];
        })->all();
    }

    public function receiversFor(string $type, int $id): array
    {
        $rows = GiftLog::query()
            ->where('context_type', $type)
            ->where('context_id', $id)
            ->selectRaw('receiver_id, SUM(gift_num) as num')
            ->groupBy('receiver_id')
            ->orderByDesc('num')
            ->get();

        $users = User::query()
            ->whereIn('id', $rows->pluck('receiver_id'))
            ->with('profile')
            ->get(['id', 'name', 'uuid'])
            ->keyBy('id');

        return $rows->map(function ($r) use ($users) {
            $user = $users->get($r->receiver_id);

            return [
                'user' => [
                    'id'     => (int) $r->receiver_id,
                    'name'   => $user?->name,
                    'avatar' => Media::url($user?->avatar),
                ],
                'num' => (int) $r->num,
            ];
        })->all();
    }

    public function countFor(string $type, int $id): int
    {
        return (int) GiftLog::query()
            ->where('context_type', $type)
            ->where('context_id', $id)
            ->sum('gift_num');
    }

    public function coinsFor(string $type, int $id): float
    {
        return (float) GiftLog::query()
            ->where('context_type', $type)
            ->where('context_id', $id)
            ->sum('total_price');
    }

    public function receivedBy(int $userId): array
    {
        return $this->groupedGiftsByColumn('receiver_id', $userId);
    }

    public function sentBy(int $userId): array
    {
        return $this->groupedGiftsByColumn('sender_id', $userId);
    }

    /**
     * Top supporters of a user: the senders who spent the most coins gifting them,
     * highest first. `avatar` is the RAW stored path (Flutter resolves the host via
     * resolveMediaUrl) so it loads on every device, not just the emulator.
     *
     * @return array<int,array{user_id:int,name:?string,uuid:?string,avatar:?string,total:int,gifts:int}>
     */
    public function topSupporters(int $userId, int $limit = 6): array
    {
        $rows = GiftLog::query()
            ->where('receiver_id', $userId)
            ->selectRaw('sender_id, SUM(total_price) as total, SUM(gift_num) as gifts')
            ->groupBy('sender_id')
            ->orderByDesc('total')
            ->limit($limit)
            ->get();

        $users = User::query()
            ->whereIn('id', $rows->pluck('sender_id'))
            ->with('profile')
            ->get(['id', 'name', 'uuid'])
            ->keyBy('id');

        return $rows->map(function ($r) use ($users) {
            $user = $users->get($r->sender_id);

            return [
                'user_id' => (int) $r->sender_id,
                'name'    => $user?->name,
                'uuid'    => $user?->uuid,
                'avatar'  => $user?->avatar, // raw path → Flutter resolveMediaUrl
                'total'   => (int) $r->total,
                'gifts'   => (int) $r->gifts,
            ];
        })->all();
    }

    public function levelsFor(int $userId): array
    {
        return app(GiftLevelService::class)->statsFor($userId);
    }

    /**
     * Gifts grouped & summed for a user filtered by one column (sender_id =
     * "sent", receiver_id = "received"). `img` is the RAW stored gift path so the
     * client resolves the host (resolveMediaUrl) and it renders on phone + emulator.
     *
     * @return array<int,array{gift_id:int,name:?string,img:?string,num:int}>
     */
    private function groupedGiftsByColumn(string $column, int $userId): array
    {
        return GiftLog::query()
            ->where($column, $userId)
            ->leftJoin('gifts', 'gifts.id', '=', 'gift_logs.gift_id')
            ->selectRaw('gift_logs.gift_id, gifts.img as img, MAX(gift_logs.gift_name) as name, SUM(gift_logs.gift_num) as num')
            ->groupBy('gift_logs.gift_id', 'gifts.img')
            ->orderByDesc('num')
            ->get()
            ->map(fn ($r) => [
                'gift_id' => (int) $r->gift_id,
                'name'    => $r->name,
                'img'     => $r->img, // raw path → Flutter resolveMediaUrl
                'num'     => (int) $r->num,
            ])
            ->all();
    }
}

