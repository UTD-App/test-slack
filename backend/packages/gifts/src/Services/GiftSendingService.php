<?php

namespace Utd\Gifts\Services;

use App\Contracts\GiftBagProvider;
use App\Contracts\GiftSender;
use App\Contracts\LuckyGiftResolver;
use App\Contracts\VipLevelProvider;
use App\Events\Gifts\GiftSent;
use App\Exceptions\InsufficientFundsException;
use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftLevel;
use Utd\Gifts\Models\GiftLog;
use Utd\Gifts\Support\GiftSettings;

/**
 * The single path every gift takes — the Base GiftSender (Moment now, Room/Live/
 * Reels later just pass a different $context). Behaviour mirrors Eagle's send flow,
 * mapped onto the package world:
 *
 *   - sender spends `coins`, receiver earns `diamonds` via the Wallet
 *     (Eagle's `di` → `diamonds` columns);
 *   - one debit for the whole batch, then a gift_log + a GiftSent event PER
 *     receiver under a shared batch id (Eagle's `room_boom_uuid`);
 *   - gift popularity (`use_count`) bumped (Eagle orders gifts by it).
 *
 * Everything Eagle layered on top — room-owner/platform/agency split, family
 * levels, PK scores, CP, charisma, room boom, sender/receiver levels, diamond
 * logs, gift banner — is NOT done here. It is the job of listeners of GiftSent in
 * the feature packages (Room/Agency/Family/Levels…). They read the context keys
 * (room_id, roomowner_id, agency_id, pk, …) off the event. While those packages
 * are not installed the event simply has no listeners and nothing breaks.
 *
 * Optional seams, used only when bound (graceful no-op otherwise):
 *   - LuckyGiftResolver  → lucky-gift plugin (type = lucky)
 *   - GiftBagProvider    → backpack plugin   (context source = bag)
 *   - VipLevelProvider   → vip package       (gift vip_level gate)
 */
class GiftSendingService implements GiftSender
{
    /** Send to a single receiver — convenience wrapper around sendMany(). */
    public function send(User $sender, User $receiver, int $giftId, int $quantity, array $context = []): array
    {
        return $this->sendMany($sender, [$receiver], $giftId, $quantity, $context);
    }

    public function sendMany(User $sender, array $receivers, int $giftId, int $quantity, array $context = []): array
    {
        if ($quantity < 1) {
            return $this->fail(__('gifts::messages.invalid_quantity'));
        }

        $receivers = array_values(array_filter($receivers));
        if ($receivers === []) {
            return $this->fail(__('gifts::messages.no_receivers'));
        }

        $gift = Gift::query()->enabled()->find($giftId);
        if (! $gift) {
            return $this->fail(__('gifts::messages.gift_not_found'));
        }

        // Lucky gifts are owned entirely by the lucky-gift plugin (its own money,
        // odds and logs). We just fan the delegation out per receiver.
        if ($gift->isLucky()) {
            return $this->delegateLucky($sender, $receivers, $giftId, $quantity, $context);
        }

        // Gifting spends the sender's coins and credits the receiver's diamonds
        // through the Wallet. Without the Wallet package the Wallet is a no-op
        // stub (isAvailable() === false), so refuse cleanly here instead of
        // failing mid-transaction. The app also hides the gift button while the
        // backend reports wallet=false, so this is the defensive second line.
        if (! Wallet::isAvailable()) {
            return $this->fail(__('gifts::messages.wallet_required'));
        }

        // VIP gate — enforced only when the vip package is installed.
        if (config('gifts.vip_gate', true)
            && (int) $gift->vip_level > 0
            && app()->bound(VipLevelProvider::class)
            && app(VipLevelProvider::class)->levelFor($sender) < (int) $gift->vip_level) {
            return $this->fail(__('gifts::messages.vip_required', ['level' => (int) $gift->vip_level]));
        }

        $spend = (string) config('gifts.spend_currency', 'coins');
        $earn  = (string) config('gifts.earn_currency', 'diamonds');
        $rate  = (float) config('gifts.receiver_rate', 1.0);

        $count       = count($receivers);
        $perReceiver = (float) $gift->price * $quantity;     // value each receiver gets
        $grandTotal  = $perReceiver * $count;                // what the sender pays
        $earnedPer   = round($perReceiver * $rate, 2);

        // The spend source: coins (Wallet) by default, or the bag plugin.
        $fromBag = ($context['source'] ?? 'coins') === 'bag';
        if ($fromBag && ! app()->bound(GiftBagProvider::class)) {
            return $this->fail(__('gifts::messages.bag_not_installed'));
        }

        // Affordability check up-front (avoids a doomed transaction).
        $affordable = $fromBag
            ? app(GiftBagProvider::class)->canAfford($sender, $gift->id, $quantity * $count)
            : Wallet::canAfford($sender, $spend, $grandTotal);
        if (! $affordable) {
            return $this->fail(__('gifts::messages.insufficient'));
        }

        // EXP conversion rates (admin-tunable; default 1.0). Sender earns exp on
        // coins spent, receiver on diamonds earned — accumulated per gift below.
        $expPerCoin    = GiftSettings::float('exp_per_coin', 1.0);
        $expPerDiamond = GiftSettings::float('exp_per_diamond', 1.0);

        try {
            $data = DB::transaction(function () use (
                $sender, $receivers, $gift, $quantity, $context, $count,
                $spend, $earn, $perReceiver, $grandTotal, $earnedPer, $fromBag,
                $expPerCoin, $expPerDiamond
            ) {
                // --- one debit for the whole batch ---
                $debitTxId = null;
                $source    = 'coins';
                if ($fromBag) {
                    app(GiftBagProvider::class)->debit($sender, $gift->id, $quantity * $count, [
                        'context' => $context,
                    ]);
                    $source = 'bag';
                } else {
                    $idempotencyKey = $context['idempotency_key'] ?? null;

                    $debit = Wallet::debit($sender, $spend, $grandTotal, 'gift_sent', array_filter([
                        'gift_id'         => $gift->id,
                        'receivers'       => array_map(fn (User $u) => $u->getKey(), $receivers),
                        'context'         => $context,
                        'idempotency_key' => $idempotencyKey,
                    ], fn ($v) => $v !== null));
                    $debitTxId = $debit->transactionId;

                    // Idempotent replay: if this debit already produced gift logs
                    // (a retry, or a concurrent duplicate that lost the wallet's
                    // idempotency-key race), return the prior batch instead of
                    // crediting receivers / writing logs a second time.
                    if ($idempotencyKey !== null) {
                        $prior = GiftLog::where('wallet_debit_tx_id', $debitTxId)->get();
                        if ($prior->isNotEmpty()) {
                            return [
                                'batch_id'     => $prior->first()->batch_id,
                                'gift_log_ids' => $prior->pluck('id')->all(),
                                'receiver_ids' => $prior->pluck('receiver_id')->all(),
                                'total'        => (float) $prior->sum('total_price'),
                                'earned_each'  => (float) $prior->first()->receiver_earned,
                                'replayed'     => true,
                            ];
                        }
                    }
                }

                $batchId   = (string) Str::uuid();
                $logIds    = [];
                $receiverIds = [];

                foreach ($receivers as $receiver) {
                    $credit = $earnedPer > 0
                        ? Wallet::credit($receiver, $earn, $earnedPer, 'gift_received', [
                            'gift_id'   => $gift->id,
                            'sender_id' => $sender->getKey(),
                            'batch_id'  => $batchId,
                            'context'   => $context,
                        ])
                        : null;

                    $log = GiftLog::create([
                        'gift_id'             => $gift->id,
                        'gift_name'           => $gift->name,
                        'sender_id'           => $sender->getKey(),
                        'receiver_id'         => $receiver->getKey(),
                        'gift_num'            => $quantity,
                        'unit_price'          => $gift->price,
                        'total_price'         => $perReceiver,
                        'spend_currency'      => $spend,
                        'earn_currency'       => $earn,
                        'receiver_earned'     => $earnedPer,
                        'context_type'        => $context['type'] ?? null,
                        'context_id'          => $context['id'] ?? null,
                        'wallet_debit_tx_id'  => $debitTxId,
                        'wallet_credit_tx_id' => $credit?->transactionId,
                        'batch_id'            => $batchId,
                        'source'              => $source,
                        'is_lucky'            => false,
                        'meta'                => $context ?: null,
                    ]);

                    $logIds[]      = $log->id;
                    $receiverIds[] = $receiver->getKey();

                    // Receiver gains EXP for the diamonds earned (drives their level).
                    app(GiftLevelService::class)->addExp(
                        (int) $receiver->getKey(),
                        GiftLevel::KIND_RECEIVER,
                        (int) round($earnedPer * $expPerDiamond),
                    );

                    // Feature packages layer their effects from here (see class doc).
                    event(new GiftSent(
                        $sender,
                        $receiver,
                        $gift->id,
                        $quantity,
                        $perReceiver,
                        $earnedPer,
                        $context + ['batch_id' => $batchId, 'source' => $source],
                    ));
                }

                // Sender gains EXP for the coins spent on the whole batch.
                app(GiftLevelService::class)->addExp(
                    (int) $sender->getKey(),
                    GiftLevel::KIND_SENDER,
                    (int) round($grandTotal * $expPerCoin),
                );

                // Popularity counter (Eagle orders gifts by use_count).
                $gift->increment('use_count', $quantity * $count);

                return [
                    'batch_id'      => $batchId,
                    'gift_log_ids'  => $logIds,
                    'receiver_ids'  => $receiverIds,
                    'total'         => $grandTotal,
                    'earned_each'   => $earnedPer,
                ];
            });
        } catch (InsufficientFundsException) {
            return $this->fail(__('gifts::messages.insufficient'));
        }

        return [
            'success' => true,
            'message' => __('gifts::messages.sent'),
            'data'    => $data,
        ];
    }

    /** Fan the lucky-gift delegation out per receiver (resolver owns the rest). */
    private function delegateLucky(User $sender, array $receivers, int $giftId, int $quantity, array $context): array
    {
        if (! app()->bound(LuckyGiftResolver::class)) {
            return $this->fail(__('gifts::messages.lucky_not_installed'));
        }

        $resolver = app(LuckyGiftResolver::class);
        $results  = [];
        foreach ($receivers as $receiver) {
            $results[] = $resolver->send($sender, $receiver, $giftId, $quantity, $context);
        }

        // Single receiver: pass the resolver's envelope straight through.
        if (count($results) === 1) {
            return $results[0];
        }

        $allOk = $results !== [] && ! in_array(false, array_column($results, 'success'), true);

        return [
            'success' => $allOk,
            'message' => __('gifts::messages.sent'),
            'data'    => ['results' => $results],
        ];
    }

    private function fail(string $message): array
    {
        return ['success' => false, 'message' => $message, 'data' => null];
    }
}
