<?php

namespace Utd\Gifts\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Utd\Gifts\Models\GiftLevel;
use Utd\Gifts\Models\GiftUserExp;
use Utd\Gifts\Support\Media;

/**
 * Resolves a user's sender/receiver LEVEL (badge) from their accumulated gift EXP:
 *   - sender level   ← stored sender_exp   (grown by coins spent    × exp_per_coin)
 *   - receiver level ← stored receiver_exp (grown by diamonds earned × exp_per_diamond)
 *
 * EXP is stored (gift_user_exp), not summed live, so it accumulates over time and
 * changing a rate only affects future gifts — it never retroactively demotes anyone.
 * The level is the highest definition of that kind whose threshold is <= the stored
 * exp (mirrors Eagle's getLevel).
 */
class GiftLevelService
{
    /** Per-user stats cache TTL (seconds). */
    private const USER_TTL = 300;

    /**
     * Sender + receiver level for a user, with badge icons (absolute URLs for the
     * app) and the raw exp totals + next thresholds (so the UI can draw progress).
     */
    public function statsFor(int $userId): array
    {
        return Cache::remember("gifts:userlevel:{$userId}", self::USER_TTL, function () use ($userId) {
            $row = GiftUserExp::find($userId);
            $senderExp   = (int) ($row->sender_exp ?? 0);
            $receiverExp = (int) ($row->receiver_exp ?? 0);

            $senderLevel   = $this->levelFor(GiftLevel::KIND_SENDER, $senderExp);
            $receiverLevel = $this->levelFor(GiftLevel::KIND_RECEIVER, $receiverExp);

            return [
                'sender_level'            => $senderLevel,
                'receiver_level'          => $receiverLevel,
                'sender_level_img'        => Media::url($this->iconFor(GiftLevel::KIND_SENDER, $senderLevel)),
                'receiver_level_img'      => Media::url($this->iconFor(GiftLevel::KIND_RECEIVER, $receiverLevel)),
                'sender_exp'              => $senderExp,
                'receiver_exp'            => $receiverExp,
                'sender_next_threshold'   => $this->nextThreshold(GiftLevel::KIND_SENDER, $senderExp),
                'receiver_next_threshold' => $this->nextThreshold(GiftLevel::KIND_RECEIVER, $receiverExp),
            ];
        });
    }

    /**
     * Add EXP to a user (atomic insert-or-increment), then drop their cached stats
     * so the new level shows immediately. $kind is sender|receiver; a non-positive
     * $delta is a no-op. Returns the user's new exp total of that kind.
     */
    public function addExp(int $userId, string $kind, int $delta): int
    {
        if (! in_array($kind, [GiftLevel::KIND_SENDER, GiftLevel::KIND_RECEIVER], true)) {
            return 0;
        }

        $column = $kind . '_exp';

        if ($delta <= 0) {
            return (int) (DB::table('gift_user_exp')->where('user_id', $userId)->value($column) ?? 0);
        }

        // Ensure the row exists, then bump the column atomically (safe under
        // concurrent sends to the same user).
        DB::table('gift_user_exp')->insertOrIgnore([
            'user_id'      => $userId,
            'sender_exp'   => 0,
            'receiver_exp' => 0,
        ]);
        DB::table('gift_user_exp')->where('user_id', $userId)->increment($column, $delta);

        $this->forget($userId);

        return (int) (DB::table('gift_user_exp')->where('user_id', $userId)->value($column) ?? 0);
    }

    /** Highest level of $kind whose threshold is <= $exp (0 = below the first level). */
    public function levelFor(string $kind, int $exp): int
    {
        $bestLevel = 0;
        $bestThreshold = -1;

        foreach ($this->definitions()[$kind] ?? [] as $row) {
            if ($exp >= $row['threshold'] && $row['threshold'] > $bestThreshold) {
                $bestThreshold = $row['threshold'];
                $bestLevel = $row['level'];
            }
        }

        return $bestLevel;
    }

    /** Threshold of the next level up for $exp, or null when already at the top. */
    public function nextThreshold(string $kind, int $exp): ?int
    {
        $next = null;

        foreach ($this->definitions()[$kind] ?? [] as $row) {
            if ($row['threshold'] > $exp && ($next === null || $row['threshold'] < $next)) {
                $next = $row['threshold'];
            }
        }

        return $next;
    }

    /** The badge icon (raw img value) for a given kind+level, or null. */
    public function iconFor(string $kind, int $level): ?string
    {
        if ($level < 1) {
            return null;
        }

        foreach ($this->definitions()[$kind] ?? [] as $row) {
            if ($row['level'] === $level) {
                return $row['img'];
            }
        }

        return null;
    }

    /** Forget the cached stats for a user (called whenever their exp changes). */
    public function forget(int $userId): void
    {
        Cache::forget("gifts:userlevel:{$userId}");
    }

    /** All level rows grouped by kind (cached). */
    private function definitions(): array
    {
        return Cache::remember('gifts:levels', (int) config('gifts.catalog_ttl', 1800), fn () => GiftLevel::query()
            ->orderBy('threshold')
            ->get(['kind', 'level', 'threshold', 'img'])
            ->groupBy('kind')
            ->map(fn ($rows) => $rows->map(fn ($r) => [
                'level'     => (int) $r->level,
                'threshold' => (int) $r->threshold,
                'img'       => $r->img,
            ])->all())
            ->all());
    }
}
