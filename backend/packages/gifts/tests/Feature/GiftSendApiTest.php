<?php

namespace Utd\Gifts\Tests\Feature;

use App\Contracts\LuckyGiftResolver;
use App\Contracts\RoomOwnerResolver;
use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;

class GiftSendApiTest extends TestCase
{
    use RefreshDatabase;

    private function gift(int $price = 100, int $type = Gift::TYPE_NORMAL): Gift
    {
        return Gift::create(['name' => 'Rose', 'e_name' => 'Rose', 'type' => $type, 'price' => $price, 'enable' => true]);
    }

    public function test_send_endpoint_debits_credits_logs_and_returns_ids(): void
    {
        $sender = User::factory()->create();
        $r1     = User::factory()->create();
        $r2     = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        $this->authed($sender)->postJson('/api/gifts/send', [
            'id'    => $gift->id,
            'toUid' => "{$r1->id},{$r2->id}",
            'num'   => 2,
        ])
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(2, 'data.ids')
            ->assertJsonPath('data.total', 400); // 100 * 2 * 2

        $this->assertEquals(600.0, Wallet::getBalance($sender, 'coins'));
        $this->assertDatabaseCount('gift_logs', 2);
    }

    public function test_send_endpoint_validation_errors_return_422(): void
    {
        $sender = User::factory()->create();

        $this->authed($sender)->postJson('/api/gifts/send', [])
            ->assertStatus(422)
            ->assertJsonPath('status', false);
    }

    public function test_send_endpoint_unknown_receivers_returns_422_no_movement(): void
    {
        $sender = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        $this->authed($sender)->postJson('/api/gifts/send', [
            'id'    => $gift->id,
            'toUid' => '999999',
            'num'   => 1,
        ])->assertStatus(422)->assertJsonPath('status', false);

        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));
        $this->assertDatabaseCount('gift_logs', 0);
    }

    public function test_send_endpoint_insufficient_balance_returns_422_no_movement(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 50, 'admin_charge');
        $gift = $this->gift(100);

        $this->authed($sender)->postJson('/api/gifts/send', [
            'id'    => $gift->id,
            'toUid' => (string) $receiver->id,
            'num'   => 1,
        ])->assertStatus(422)->assertJsonPath('status', false);

        $this->assertEquals(50.0, Wallet::getBalance($sender, 'coins'));
        $this->assertDatabaseCount('gift_logs', 0);
    }

    public function test_send_endpoint_bag_source_fails_without_bag_provider(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        $this->authed($sender)->postJson('/api/gifts/send', [
            'id'    => $gift->id,
            'toUid' => (string) $receiver->id,
            'num'   => 1,
            'type'  => 'bag',
        ])->assertStatus(422)->assertJsonPath('status', false);

        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));
        $this->assertDatabaseCount('gift_logs', 0);
    }

    public function test_send_endpoint_delegates_lucky_to_resolver_without_core_movement(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $lucky = $this->gift(100, Gift::TYPE_LUCKY);

        app()->bind(LuckyGiftResolver::class, fn () => new class implements LuckyGiftResolver {
            public function send(User $sender, User $receiver, int $giftId, int $quantity, array $context = []): array
            {
                return ['success' => true, 'message' => 'lucky', 'data' => ['receivers_ids' => [$receiver->getKey()], 'won' => true]];
            }
        });

        $this->authed($sender)->postJson('/api/gifts/send', [
            'id'    => $lucky->id,
            'toUid' => (string) $receiver->id,
            'num'   => 1,
        ])
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data.ids');

        // Core never touched the wallet / logs — the resolver owns lucky money.
        $this->assertEquals(1000.0, Wallet::getBalance($sender, 'coins'));
        $this->assertDatabaseCount('gift_logs', 0);
    }

    public function test_send_endpoint_credits_room_owner_their_cut(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        $owner    = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        // The cut goes to the owner resolved from the room (the seam), NEVER the
        // client-supplied owner_id. Bind a fake resolver so this gifts test stays
        // independent of any room package, and pass a SPOOFED owner_id to prove
        // it is ignored.
        app()->bind(RoomOwnerResolver::class, fn () => new class ($owner->id) implements RoomOwnerResolver {
            public function __construct(private int $ownerId)
            {
            }

            public function ownerId(int $roomId): ?int
            {
                return $roomId === 42 ? $this->ownerId : null;
            }
        });

        $this->authed($sender)->postJson('/api/gifts/send', [
            'id'       => $gift->id,
            'toUid'    => (string) $receiver->id,
            'num'      => 2,
            'room_id'  => 42,
            'owner_id' => 999999, // spoofed — must be ignored
        ])->assertStatus(200)->assertJsonPath('status', true);

        // value = 100 * 2 = 200; owner cut = 3% = 6 diamonds, to the RESOLVED owner
        // (the spoofed owner_id=999999 was ignored, else $owner would have 0).
        $this->assertEquals(6.0, Wallet::getBalance($owner, 'diamonds'));
        // receiver still earns the full value; sender pays the gift price only.
        $this->assertEquals(200.0, Wallet::getBalance($receiver, 'diamonds'));
        $this->assertEquals(800.0, Wallet::getBalance($sender, 'coins'));
    }

    public function test_non_room_send_does_not_credit_any_owner(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift = $this->gift(100);

        // No owner_id → no room-owner cut applied.
        $this->authed($sender)->postJson('/api/gifts/send', [
            'id'    => $gift->id,
            'toUid' => (string) $receiver->id,
            'num'   => 1,
        ])->assertStatus(200);

        $this->assertEquals(100.0, Wallet::getBalance($receiver, 'diamonds'));
        $this->assertEquals(900.0, Wallet::getBalance($sender, 'coins'));
    }

    private function authed(User $user): self
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('t')->plainTextToken);
    }
}
