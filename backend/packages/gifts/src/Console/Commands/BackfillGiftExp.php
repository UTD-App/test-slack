<?php

namespace Utd\Gifts\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Utd\Gifts\Support\GiftSettings;

/**
 * One-time backfill of accumulated gift EXP from the historical gift_logs, so
 * existing users keep their levels after the switch from live-sum to stored exp.
 *
 *   sender_exp   = round(SUM(total_price)     as sender   × exp_per_coin)
 *   receiver_exp = round(SUM(receiver_earned) as receiver × exp_per_diamond)
 *
 * Idempotent: it OVERWRITES gift_user_exp from the logs, so re-running it simply
 * recomputes the same totals (run again only after changing a rate if you want
 * history re-valued). Run once after deploying the EXP migrations.
 */
class BackfillGiftExp extends Command
{
    protected $signature = 'gifts:backfill-exp';

    protected $description = 'Backfill accumulated gift EXP (sender/receiver) from gift_logs';

    public function handle(): int
    {
        $expPerCoin    = GiftSettings::float('exp_per_coin', 1.0);
        $expPerDiamond = GiftSettings::float('exp_per_diamond', 1.0);

        $this->info("Backfilling gift EXP (coin×{$expPerCoin}, diamond×{$expPerDiamond})…");

        // Sum spent (as sender) and earned (as receiver) per user from the logs.
        $sent = DB::table('gift_logs')
            ->selectRaw('sender_id as user_id, SUM(total_price) as total')
            ->whereNotNull('sender_id')
            ->groupBy('sender_id')
            ->pluck('total', 'user_id');

        $received = DB::table('gift_logs')
            ->selectRaw('receiver_id as user_id, SUM(receiver_earned) as total')
            ->whereNotNull('receiver_id')
            ->groupBy('receiver_id')
            ->pluck('total', 'user_id');

        $userIds = $sent->keys()->merge($received->keys())->unique();

        if ($userIds->isEmpty()) {
            $this->info('No gift logs found — nothing to backfill.');

            return self::SUCCESS;
        }

        $now  = now();
        $rows = $userIds->map(fn ($id) => [
            'user_id'      => (int) $id,
            'sender_exp'   => (int) round(((float) ($sent[$id] ?? 0)) * $expPerCoin),
            'receiver_exp' => (int) round(((float) ($received[$id] ?? 0)) * $expPerDiamond),
            'created_at'   => $now,
            'updated_at'   => $now,
        ])->all();

        foreach (array_chunk($rows, 500) as $chunk) {
            DB::table('gift_user_exp')->upsert($chunk, ['user_id'], ['sender_exp', 'receiver_exp', 'updated_at']);
        }

        // Drop per-user level caches so the recomputed exp shows immediately.
        $userIds->each(fn ($id) => Cache::forget("gifts:userlevel:{$id}"));

        $this->info('Backfilled gift EXP for ' . $userIds->count() . ' user(s).');

        return self::SUCCESS;
    }
}
