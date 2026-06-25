<?php

namespace Utd\Gifts\Tests\Feature;

use App\Contracts\GiftBagProvider;
use App\Contracts\GiftSender;
use App\Contracts\LuckyGiftResolver;
use App\Contracts\VipLevelProvider;
use App\Events\Gifts\GiftSent;
use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftLog;
use Utd\Gifts\Services\GiftSendingService;

class GiftSendingTest extends TestCase
{
    use RefreshDatabase;

    private function gift(int $price = 100, int $type = Gift::TYPE_NORMAL, int $vip = 0): Gift
    {
        return Gift::create([
            'name'      => 'Rose',
            'e_name'    => 'Rose',
            'type'      => $type,
            'price'     => $price,
            'vip_level' => $vip,
            'enable'    => true,
        ]);
    }

    public function test_gift_sender_is_bound(): void
    {
        $this->assertInstanceOf(GiftSendingService::class, app(GiftSender::class));
    }

    public function test_send_gift_debits_coins_credits_diamonds_logs_and_emits_event(): void
    {
        Event::fake([GiftSent::class]);
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        $res = app(GiftSender::class)->send($sender, $receiver, $gift->id, 2, ['type' => 'moment', 'id' => 5]);

        $this->assertTrue($res['success']);
        $this->assertEquals(800.0, Wallet::getBalance($sender, 'coins'));      // 1000 - 100*2
        $this->assertEquals(200.0, Wallet::getBalance($receiver, 'diamonds')); // earned

        $this->assertDatabaseHas('gift_logs', [
            'sender_id'    => $sender->id,
            'receiver_id'  => $receiver->id,
            'gift_id'      => $gift->id,
            'gift_num'     => 2,
            'total_price'  => 200,
            'receiver_earned' => 200,
            'context_type' => 'moment',
            'context_id'   => 5,
            'source'       => 'coins',
            'is_lucky'     => false,
        ]);

        $this->assertEquals(2, $gift->fresh()->use_count);
        Event::assertDispatched(GiftSent::class);
    }

    public function test_send_many_charges_once_logs_and_emits_per_receiver_under_one_batch(): void
    {
        Event::fake([GiftSent::class]);
        $sender = User::factory()->create();
        $r1     = User::factory()->create();
        $r2     = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        $res = app(GiftSender::class)->sendMany($sender, [$r1, $r2], $gift->id, 2, ['type' => 'room', 'id' => 9]);

        $this->assertTrue($res['success']);
        $this->assertEquals(600.0, Wallet::getBalance($sender, 'coins'));   // 1000 - 100*2*2
        $this->assertEquals(200.0, Wallet::getBalance($r1, 'diamonds'));
        $this->assertEquals(200.0, Wallet::getBalance($r2, 'diamonds'));

        $this->assertDatabaseCount('gift_logs', 2);
        $this->assertCount(1, GiftLog::query()->pluck('batch_id')->unique()); // shared batch
        $this->assertEquals(4, $gift->fresh()->use_count);                    // 2 * 2 receivers

        Event::assertDispatchedTimes(GiftSent::class, 2);
    }

    public function test_send_gift_fails_when_insufficient_balance_with_no_movement(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 50, 'admin_charge');
        $gift = $this->gift(100);

        $res = app(GiftSender::class)->send($sender, $receiver, $gift->id, 1);

        $this->assertFalse($res['success']);
        $this->assertEquals(50.0, Wallet::getBalance($sender, 'coins'));
        $this->assertEquals(0.0, Wallet::getBalance($receiver, 'diamonds'));
        $this->assertDatabaseCount('gift_logs', 0);
    }

    public function test_send_gift_fails_for_disabled_or_missing_gift(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');

        $disabled = $this->gift(10);
        $disabled->update(['enable' => false]);

        $this->assertFalse(app(GiftSender::class)->send($sender, $receiver, $disabled->id, 1)['success']);
        $this->assertFalse(app(GiftSender::class)->send($sender, $receiver, 999999, 1)['success']);
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));
    }

    public function test_send_fails_with_no_receivers_or_invalid_quantity(): void
    {
        $sender = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        $this->assertFalse(app(GiftSender::class)->sendMany($sender, [], $gift->id, 1)['success']);
        $this->assertFalse(app(GiftSender::class)->send($sender, User::factory()->create(), $gift->id, 0)['success']);
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));
    }

    // ----- VIP gate (App\Contracts\VipLevelProvider) -----

    public function test_vip_gate_blocks_below_level_when_provider_is_bound(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100, Gift::TYPE_NORMAL, vip: 5);

        app()->bind(VipLevelProvider::class, fn () => new class implements VipLevelProvider {
            public function levelFor(User $user): int { return 1; }
        });

        $res = app(GiftSender::class)->send($sender, $receiver, $gift->id, 1);

        $this->assertFalse($res['success']);
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));
    }

    public function test_vip_gate_is_skipped_when_no_provider_bound(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100, Gift::TYPE_NORMAL, vip: 5);

        $res = app(GiftSender::class)->send($sender, $receiver, $gift->id, 1);

        $this->assertTrue($res['success']); // VIP not installed → gate skipped
        $this->assertEquals(900.0, Wallet::getBalance($sender, 'coins'));
    }

    // ----- Bag source (App\Contracts\GiftBagProvider) -----

    public function test_bag_send_fails_gracefully_without_a_bag_provider(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        $res = app(GiftSender::class)->send($sender, $receiver, $gift->id, 1, ['source' => 'bag']);

        $this->assertFalse($res['success']);
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins')); // wallet untouched
        $this->assertDatabaseCount('gift_logs', 0);
    }

    public function test_bag_send_uses_provider_keeps_coins_and_still_credits_receiver(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        app()->bind(GiftBagProvider::class, fn () => new class implements GiftBagProvider {
            public function canAfford(User $user, int $giftId, int $quantity): bool { return true; }
            public function debit(User $user, int $giftId, int $quantity, array $meta = []): mixed { return 'bag-ref'; }
        });

        $res = app(GiftSender::class)->send($sender, $receiver, $gift->id, 1, ['source' => 'bag']);

        $this->assertTrue($res['success']);
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));    // coins NOT spent
        $this->assertEquals(100.0, Wallet::getBalance($receiver, 'diamonds')); // receiver still earns
        $this->assertDatabaseHas('gift_logs', ['receiver_id' => $receiver->id, 'source' => 'bag']);
    }

    // ----- Lucky (App\Contracts\LuckyGiftResolver) -----

    public function test_lucky_gift_is_disabled_without_the_plugin(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $lucky = $this->gift(100, Gift::TYPE_LUCKY);

        $res = app(GiftSender::class)->send($sender, $receiver, $lucky->id, 1);

        $this->assertFalse($res['success']);
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins')); // untouched
    }

    public function test_lucky_gift_is_delegated_to_the_resolver_when_bound(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $lucky = $this->gift(100, Gift::TYPE_LUCKY);

        app()->bind(LuckyGiftResolver::class, fn () => new class implements LuckyGiftResolver {
            public function send(User $sender, User $receiver, int $giftId, int $quantity, array $context = []): array
            {
                return ['success' => true, 'message' => 'lucky', 'data' => ['won' => true]];
            }
        });

        $res = app(GiftSender::class)->send($sender, $receiver, $lucky->id, 1);

        $this->assertTrue($res['success']);
        $this->assertEquals(['won' => true], $res['data']);
        // Core did not touch the wallet — the resolver owns lucky money.
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));
        $this->assertDatabaseCount('gift_logs', 0);
    }
}
