<?php

namespace Utd\Wallet\Tests\Feature;

use App\Exceptions\InsufficientFundsException;
use App\Facades\Wallet;
use App\Models\AdminUser;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Wallet\Models\Charge;
use Utd\Wallet\Models\WalletTransaction;
use Utd\Wallet\Services\ChargeService;

/**
 * ChargeService — the single entry point for a manual charge (admin → user).
 * Moves balance through the Wallet (ledger) and records a Charge history row
 * linked to that ledger entry.
 */
class ChargeServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): ChargeService
    {
        return app(ChargeService::class);
    }

    public function test_charge_credits_records_history_and_links_ledger(): void
    {
        $admin = AdminUser::create(['name' => 'A', 'email' => 'a@a.com', 'password' => 'secret']);
        $user  = User::factory()->create();

        $charge = $this->service()->charge($user, 500, 'charge', $admin, 'welcome bonus', 'coins', 9.99);

        $this->assertEquals(500.0, Wallet::getBalance($user, 'coins'));
        $this->assertSame('coins', $charge->currency);
        $this->assertEquals(500, (float) $charge->amount);
        $this->assertEquals(0, (float) $charge->balance_before);
        $this->assertEquals(500, (float) $charge->balance_after);
        $this->assertEquals(9.99, (float) $charge->usd);
        $this->assertSame('welcome bonus', $charge->reason);

        // Morphs point at the right models.
        $this->assertSame(AdminUser::class, $charge->charger_type);
        $this->assertEquals($admin->id, $charge->charger_id);
        $this->assertSame(User::class, $charge->target_type);
        $this->assertEquals($user->id, $charge->target_id);
        $this->assertTrue($charge->charger->is($admin));
        $this->assertTrue($charge->target->is($user));

        // Linked ledger row.
        $this->assertNotNull($charge->wallet_transaction_id);
        $tx = WalletTransaction::find($charge->wallet_transaction_id);
        $this->assertSame('admin_charge', $tx->type);
        $this->assertEquals(500, (float) $tx->amount);
        $this->assertSame('welcome bonus', $tx->meta['reason']);
        $this->assertTrue($charge->walletTransaction->is($tx));
    }

    public function test_deduct_records_negative_amount(): void
    {
        $user = User::factory()->create();
        $this->service()->charge($user, 300, 'charge');

        $charge = $this->service()->charge($user, 100, 'deduct');

        $this->assertEquals(200.0, Wallet::getBalance($user, 'coins'));
        $this->assertEquals(-100, (float) $charge->amount);
        $this->assertEquals(300, (float) $charge->balance_before);
        $this->assertEquals(200, (float) $charge->balance_after);

        $tx = WalletTransaction::find($charge->wallet_transaction_id);
        $this->assertSame('admin_deduct', $tx->type);
        $this->assertEquals(-100, (float) $tx->amount);
    }

    public function test_deduct_beyond_balance_throws_and_writes_no_charge(): void
    {
        $user = User::factory()->create();
        $this->service()->charge($user, 50, 'charge');

        try {
            $this->service()->charge($user, 80, 'deduct');
            $this->fail('Expected InsufficientFundsException');
        } catch (InsufficientFundsException) {
            // expected — whole transaction rolls back
        }

        $this->assertEquals(50.0, Wallet::getBalance($user, 'coins'));
        // Only the initial charge survives; the failed deduct left no Charge row.
        $this->assertSame(1, Charge::where('target_id', $user->id)->count());
    }

    public function test_system_charge_has_no_charger(): void
    {
        $user = User::factory()->create();

        $charge = $this->service()->charge($user, 25, 'charge'); // charger = null (system)

        $this->assertNull($charge->charger_type);
        $this->assertNull($charge->charger_id);
        $this->assertNull($charge->charger);
        $this->assertEquals(25.0, Wallet::getBalance($user, 'coins'));
    }

    public function test_charge_defaults_to_coins_currency(): void
    {
        $user = User::factory()->create();

        $charge = $this->service()->charge($user, 10); // direction defaults to 'charge', currency to 'coins'

        $this->assertSame('coins', $charge->currency);
        $this->assertEquals(10, (float) $charge->amount);
    }
}
