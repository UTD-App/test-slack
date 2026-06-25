<?php

namespace Utd\Wallet\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Wallet\Models\Coin;
use Utd\Wallet\Models\PaymentCoin;

/**
 * The read-only coin catalogue API used by the recharge screen:
 * GET /api/coins and /api/coins/payment-methods. (The purchase itself is the
 * payment package's job; this just lists what's buyable.)
 */
class CoinApiTest extends TestCase
{
    use RefreshDatabase;

    private function authHeaders(User $user): array
    {
        return ['Authorization' => 'Bearer ' . $user->createToken('test')->plainTextToken];
    }

    public function test_coins_requires_authentication(): void
    {
        $this->getJson('/api/coins')->assertUnauthorized();
    }

    public function test_coins_returns_packages_ordered_by_sort_then_usd(): void
    {
        $user = User::factory()->create();
        Coin::create(['usd' => 5,  'coin' => 500,  'sort' => 2]);
        Coin::create(['usd' => 1,  'coin' => 100,  'sort' => 1]);
        Coin::create(['usd' => 10, 'coin' => 1000, 'sort' => 1]);

        $data = $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/coins')
            ->assertOk()
            ->json('data');

        // sort asc, then usd asc → [sort1/usd1], [sort1/usd10], [sort2/usd5]
        $this->assertSame([1.0, 10.0, 5.0], array_map(fn ($c) => (float) $c['usd'], $data));
    }

    public function test_coins_excludes_soft_deleted_packages(): void
    {
        $user = User::factory()->create();
        Coin::create(['usd' => 1, 'coin' => 100]);
        $gone = Coin::create(['usd' => 2, 'coin' => 200]);
        $gone->delete();

        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/coins')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_coins_filter_by_payment_gateway(): void
    {
        $user  = User::factory()->create();
        $group = PaymentCoin::create(['title' => 'Card', 'type' => 'card', 'package_type' => 'user']);
        Coin::create(['usd' => 1, 'coin' => 100, 'payment_gateway_id' => $group->id]);
        Coin::create(['usd' => 2, 'coin' => 200]); // ungrouped

        $this->withHeaders($this->authHeaders($user))
            ->getJson("/api/coins?payment_gateway_id={$group->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.payment_gateway_id', $group->id);
    }

    public function test_payment_methods_returns_active_user_groups_only(): void
    {
        $user = User::factory()->create();
        PaymentCoin::create(['title' => 'Active', 'type' => 'card',   'package_type' => 'user',   'status' => true]);
        PaymentCoin::create(['title' => 'Off',    'type' => 'wallet', 'package_type' => 'user',   'status' => false]);
        PaymentCoin::create(['title' => 'Agency', 'type' => 'card',   'package_type' => 'shipping_agency', 'status' => true]);

        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/coins/payment-methods')
            ->assertOk()
            ->assertJsonCount(1, 'data') // only the active, user-typed group
            ->assertJsonPath('data.0.title', 'Active');
    }

    public function test_payment_methods_filter_by_type(): void
    {
        $user = User::factory()->create();
        PaymentCoin::create(['title' => 'Card',   'type' => 'card',   'package_type' => 'user', 'status' => true]);
        PaymentCoin::create(['title' => 'Wallet', 'type' => 'wallet', 'package_type' => 'user', 'status' => true]);

        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/coins/payment-methods?type=wallet')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.type', 'wallet');
    }
}
