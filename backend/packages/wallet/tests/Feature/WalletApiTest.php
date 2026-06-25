<?php

namespace Utd\Wallet\Tests\Feature;

use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Arr;
use Tests\TestCase;

/**
 * The app-facing wallet API: GET /api/wallet/balances and /api/wallet/transactions.
 */
class WalletApiTest extends TestCase
{
    use RefreshDatabase;

    private function authHeaders(User $user): array
    {
        return ['Authorization' => 'Bearer ' . $user->createToken('test')->plainTextToken];
    }

    public function test_balances_requires_authentication(): void
    {
        $this->getJson('/api/wallet/balances')->assertUnauthorized();
    }

    public function test_balances_lists_the_coin_wallet(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 250, 'admin_charge');

        $data = $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/wallet/balances')
            ->assertOk()
            ->assertJsonPath('status', true)
            ->json('data');

        // Coins must be present with the right balance — other packages may add more currencies.
        $coins = Arr::first($data, fn ($row) => $row['currency'] === 'coins');
        $this->assertNotNull($coins, 'balances response is missing the coins wallet');
        $this->assertEquals(250, $coins['balance']);
        $this->assertEquals(250, $coins['available']);
    }

    public function test_transactions_requires_authentication(): void
    {
        $this->getJson('/api/wallet/transactions')->assertUnauthorized();
    }

    public function test_transactions_returns_flat_newest_first_payload(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 10, 'admin_charge', ['reason' => 'Welcome bonus']);
        Wallet::debit($user, 'coins', 4, 'gift');

        // Newest first → the gift debit is index 0, the credit is index 1.
        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/wallet/transactions?currency=coins')
            ->assertOk()
            ->assertJsonPath('data.total', 2)
            ->assertJsonPath('data.data.0.direction', 'debit')
            ->assertJsonPath('data.data.0.type', 'gift')
            ->assertJsonPath('data.data.0.amount', -4)
            ->assertJsonPath('data.data.0.abs_amount', 4)
            ->assertJsonPath('data.data.0.reason', 'gift') // no meta reason → falls back to type
            ->assertJsonPath('data.data.1.direction', 'credit')
            ->assertJsonPath('data.data.1.reason', 'Welcome bonus')
            ->assertJsonPath('data.data.1.balance_after', 10);
    }

    public function test_transactions_filters_by_type(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 10, 'admin_charge');
        Wallet::debit($user, 'coins', 4, 'gift');

        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/wallet/transactions?currency=coins&type=gift')
            ->assertOk()
            ->assertJsonPath('data.total', 1)
            ->assertJsonPath('data.data.0.type', 'gift');
    }

    public function test_transactions_filters_by_date_window(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 10, 'admin_charge');

        // A window starting in the far future returns nothing.
        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/wallet/transactions?currency=coins&start_date=2999-01-01')
            ->assertOk()
            ->assertJsonPath('data.total', 0);

        // From today onwards includes it.
        $today = now()->toDateString();
        $this->withHeaders($this->authHeaders($user))
            ->getJson("/api/wallet/transactions?currency=coins&start_date={$today}")
            ->assertOk()
            ->assertJsonPath('data.total', 1);
    }

    public function test_transactions_respects_per_page(): void
    {
        $user = User::factory()->create();
        for ($i = 0; $i < 5; $i++) {
            Wallet::credit($user, 'coins', 1, 'admin_charge');
        }

        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/wallet/transactions?currency=coins&per_page=2')
            ->assertOk()
            ->assertJsonPath('data.total', 5)
            ->assertJsonPath('data.per_page', 2)
            ->assertJsonCount(2, 'data.data');
    }

    public function test_transactions_caps_per_page_to_prevent_unbounded_pulls(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 1, 'admin_charge');

        // A huge per_page is clamped to the 100 ceiling.
        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/wallet/transactions?currency=coins&per_page=1000000')
            ->assertOk()
            ->assertJsonPath('data.per_page', 100);
    }

    public function test_transactions_only_returns_the_authenticated_users_rows(): void
    {
        $me    = User::factory()->create();
        $other = User::factory()->create();
        Wallet::credit($me, 'coins', 10, 'admin_charge');
        Wallet::credit($other, 'coins', 99, 'admin_charge');

        $this->withHeaders($this->authHeaders($me))
            ->getJson('/api/wallet/transactions?currency=coins')
            ->assertOk()
            ->assertJsonPath('data.total', 1)
            ->assertJsonPath('data.data.0.balance_after', 10);
    }
}
