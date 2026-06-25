<?php

namespace Utd\Wallet\Tests\Feature;

use App\Models\AdminUser;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Wallet\Models\Charge;
use Utd\Wallet\Models\Coin;
use Utd\Wallet\Models\CoinLog;
use Utd\Wallet\Models\PaymentCoin;
use Utd\Wallet\Models\UserWallet;
use Utd\Wallet\Models\WalletTransaction;

/**
 * Model contracts: casts, accessors, scopes and relationships the rest of the
 * package (and the dashboard) rely on.
 */
class WalletModelsTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_wallet_available_accessor_and_relations(): void
    {
        $user   = User::factory()->create();
        // balance/held are guarded (only DatabaseWallet moves them) — set via forceFill.
        $wallet = UserWallet::create(['user_id' => $user->id, 'currency' => 'coins']);
        $wallet->forceFill(['balance' => 100, 'held' => 30])->save();

        $this->assertSame(70.0, $wallet->available);
        $this->assertTrue($wallet->user->is($user));

        $a = WalletTransaction::create(['wallet_id' => $wallet->id, 'user_id' => $user->id, 'currency' => 'coins', 'type' => 'admin_charge', 'amount' => 100, 'balance_before' => 0, 'balance_after' => 100]);
        $b = WalletTransaction::create(['wallet_id' => $wallet->id, 'user_id' => $user->id, 'currency' => 'coins', 'type' => 'gift', 'amount' => -30, 'balance_before' => 100, 'balance_after' => 70]);
        // Distinct timestamps so the newest-first order is unambiguous.
        $a->forceFill(['created_at' => now()->subMinute()])->save();
        $b->forceFill(['created_at' => now()])->save();

        // transactions() is ordered newest first.
        $this->assertSame([$b->id, $a->id], $wallet->fresh()->transactions->pluck('id')->all());
    }

    public function test_wallet_transaction_casts_and_morph_reference(): void
    {
        $user = User::factory()->create();
        $ref  = User::factory()->create();
        $wallet = UserWallet::create(['user_id' => $user->id, 'currency' => 'coins']);
        $tx = WalletTransaction::create([
            'wallet_id'      => $wallet->id,
            'user_id'        => $user->id,
            'currency'       => 'coins',
            'type'           => 'gift',
            'amount'         => -5,
            'balance_before' => 10,
            'balance_after'  => 5,
            'meta'           => ['reason' => 'gift sent'],
            'reference_type' => User::class,
            'reference_id'   => $ref->id,
        ]);

        $tx->refresh();
        $this->assertIsArray($tx->meta);
        $this->assertSame('gift sent', $tx->meta['reason']);
        $this->assertTrue($tx->user->is($user));
        $this->assertTrue($tx->reference->is($ref));
    }

    public function test_charge_casts_and_morphs(): void
    {
        $admin = AdminUser::create(['name' => 'A', 'email' => 'admin@a.com', 'password' => 'secret']);
        $user  = User::factory()->create();
        $charge = Charge::create([
            'charger_type'        => $admin->getMorphClass(),
            'charger_id'          => $admin->id,
            'target_type'         => $user->getMorphClass(),
            'target_id'           => $user->id,
            'currency'            => 'coins',
            'amount'              => 500,
            'balance_before'      => 0,
            'balance_after'       => 500,
            'usd'                 => 9.999,
            'is_used_transferred' => 1,
            'meta'                => ['note' => 'x'],
        ]);

        $charge->refresh();
        $this->assertTrue($charge->is_used_transferred);
        $this->assertIsArray($charge->meta);
        $this->assertEquals(10.0, round((float) $charge->usd, 2)); // decimal:3
        $this->assertTrue($charge->charger->is($admin));
        $this->assertTrue($charge->target->is($user));
    }

    public function test_coin_soft_deletes_and_relations(): void
    {
        $group = PaymentCoin::create(['title' => 'Card', 'type' => 'card', 'package_type' => 'user']);
        $coin  = Coin::create(['usd' => 5, 'coin' => 500, 'payment_gateway_id' => $group->id]);

        $this->assertTrue($coin->paymentCoin->is($group));
        $this->assertTrue($group->coins->contains($coin));

        $coin->delete();
        $this->assertSoftDeleted($coin);
        $this->assertSame(0, Coin::count());
        $this->assertSame(1, Coin::withTrashed()->count());
    }

    public function test_payment_coin_status_cast_and_active_scope(): void
    {
        PaymentCoin::create(['title' => 'On',  'type' => 'card',   'package_type' => 'user', 'status' => true]);
        PaymentCoin::create(['title' => 'Off', 'type' => 'wallet', 'package_type' => 'user', 'status' => false]);

        $active = PaymentCoin::active()->get();
        $this->assertCount(1, $active);
        $this->assertTrue($active->first()->status);
        $this->assertIsBool($active->first()->status);
    }

    public function test_coin_log_relations_and_casts(): void
    {
        $user = User::factory()->create();
        $coin = Coin::create(['usd' => 5, 'coin' => 500]);
        $log  = CoinLog::create([
            'user_id'        => $user->id,
            'coin_id'        => $coin->id,
            'paid_usd'       => 5.0,
            'obtained_coins' => 500,
            'status'         => 1,
        ]);

        $this->assertTrue($log->user->is($user));
        $this->assertTrue($log->coin->is($coin));
        $this->assertIsInt($log->obtained_coins);
        $this->assertSame(1, $log->status);
    }
}
