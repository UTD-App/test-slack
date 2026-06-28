<?php

namespace Utd\Gifts\Tests\Feature;

use App\Contracts\LuckyGiftResolver;
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

    private function authed(User $user): self
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('t')->plainTextToken);
    }
}
