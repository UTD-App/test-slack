<?php

namespace Utd\Wallet\Tests\Feature;

use App\Contracts\WalletContract;
use App\Exceptions\InsufficientFundsException;
use App\Exceptions\WalletProviderMissingException;
use App\Facades\Wallet;
use App\Models\User;
use App\Services\Wallet\NullWallet;
use App\Support\Wallet\WalletResult;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Wallet\Models\Charge;
use Utd\Wallet\Models\CoinLog;
use Utd\Wallet\Models\PaymentCoin;
use Utd\Wallet\Models\UserWallet;
use Utd\Wallet\Models\WalletTransaction;
use Utd\Wallet\Services\ChargeService;
use Utd\Wallet\Services\DatabaseWallet;

/**
 * Gap-fill unit coverage for wallet internals NOT exercised by the existing
 * ChargeServiceTest / DatabaseWalletTest / WalletModelsTest: bcmath/money
 * precision, debit idempotency replay, the held/available boundary inside move(),
 * multi-currency charges, the morph reference, NullWallet write/read semantics,
 * and the WalletResult DTO.
 */
class InternalLogicTest extends TestCase
{
    use RefreshDatabase;

    private function wallet(): DatabaseWallet
    {
        return app(DatabaseWallet::class);
    }

    // ----------------------------------------------------------------------
    // DatabaseWallet::money() precision (via public credit, stored decimal(20,2))
    // ----------------------------------------------------------------------

    public function test_credit_stores_two_decimal_precision_without_float_drift(): void
    {
        $user = User::factory()->create();

        // Repeated 0.10 credits must not accumulate binary-float drift.
        for ($i = 0; $i < 10; $i++) {
            Wallet::credit($user, 'coins', 0.10, 'gift');
        }

        $this->assertSame('1.00', UserWallet::where('user_id', $user->id)->value('balance'));
        $this->assertEquals(1.0, Wallet::getBalance($user, 'coins'));
    }

    public function test_credit_rounds_to_two_decimals(): void
    {
        $user = User::factory()->create();

        $res = Wallet::credit($user, 'coins', 10.999, 'gift'); // → 11.00

        $this->assertEquals(11.0, $res->balance);
        $this->assertSame('11.00', UserWallet::where('user_id', $user->id)->value('balance'));
    }

    public function test_ledger_amount_is_signed_credit_positive_debit_negative(): void
    {
        $user = User::factory()->create();
        $c = Wallet::credit($user, 'coins', 100, 'admin_charge');
        $d = Wallet::debit($user, 'coins', 40, 'gift');

        $this->assertSame('100.00', WalletTransaction::find($c->transactionId)->amount);
        $this->assertSame('-40.00', WalletTransaction::find($d->transactionId)->amount);
    }

    // ----------------------------------------------------------------------
    // Idempotency — debit + global (not per-user) + replay shape
    // ----------------------------------------------------------------------

    public function test_debit_idempotency_key_replays_instead_of_double_debiting(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');

        $first  = Wallet::debit($user, 'coins', 30, 'gift', ['idempotency_key' => 'spend-1']);
        $second = Wallet::debit($user, 'coins', 30, 'gift', ['idempotency_key' => 'spend-1']);

        $this->assertSame($first->transactionId, $second->transactionId);
        $this->assertEquals(70.0, Wallet::getBalance($user, 'coins')); // moved once
        $this->assertSame(1, WalletTransaction::where('type', 'gift')->count());
    }

    public function test_idempotency_replay_returns_original_amount_and_balance(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');

        $first  = Wallet::debit($user, 'coins', 25, 'gift', ['idempotency_key' => 'k']);
        $second = Wallet::debit($user, 'coins', 25, 'gift', ['idempotency_key' => 'k']);

        // resultFromTransaction: amount is the absolute value, balance is the row's after.
        $this->assertEquals(25.0, $second->amount);
        $this->assertEquals($first->balance, $second->balance);
        $this->assertSame('gift', $second->reason);
        $this->assertTrue($second->success);
    }

    public function test_idempotency_key_is_global_across_users(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();
        Wallet::credit($a, 'coins', 100, 'admin_charge');

        $first = Wallet::credit($a, 'coins', 10, 'promo', ['idempotency_key' => 'shared']);
        // Same key from a different user replays the FIRST row (key is globally unique),
        // so user B is NOT credited.
        $second = Wallet::credit($b, 'coins', 10, 'promo', ['idempotency_key' => 'shared']);

        $this->assertSame($first->transactionId, $second->transactionId);
        $this->assertSame(0.0, Wallet::getBalance($b, 'coins'));
        $this->assertSame(1, WalletTransaction::where('idempotency_key', 'shared')->count());
    }

    // ----------------------------------------------------------------------
    // move() — held / available boundary
    // ----------------------------------------------------------------------

    public function test_debit_of_exactly_available_succeeds_leaving_held(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');
        UserWallet::where('user_id', $user->id)->where('currency', 'coins')->update(['held' => 30]);
        // available = 100 - 30 = 70

        $res = Wallet::debit($user, 'coins', 70, 'withdraw'); // exactly available

        $this->assertEquals(30.0, $res->balance);                  // balance drops by 70
        $this->assertEquals(30.0, Wallet::getBalance($user, 'coins'));
    }

    public function test_debit_one_cent_over_available_is_rejected(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');
        UserWallet::where('user_id', $user->id)->where('currency', 'coins')->update(['held' => 30]);

        $this->expectException(InsufficientFundsException::class);
        Wallet::debit($user, 'coins', 70.01, 'withdraw'); // 0.01 over available
    }

    // ----------------------------------------------------------------------
    // lockOrCreateWallet — one row per (user, currency)
    // ----------------------------------------------------------------------

    public function test_repeated_moves_never_create_a_second_wallet_row(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 10, 'a');
        Wallet::credit($user, 'coins', 10, 'b');
        Wallet::debit($user, 'coins', 5, 'c');

        $this->assertSame(1, UserWallet::where('user_id', $user->id)->where('currency', 'coins')->count());
        $this->assertEquals(15.0, Wallet::getBalance($user, 'coins'));
    }

    // ----------------------------------------------------------------------
    // Reference morph (non-User type) on the ledger
    // ----------------------------------------------------------------------

    public function test_ledger_reference_morph_resolves_to_a_non_user_model(): void
    {
        $user = User::factory()->create();
        $admin = $this->makeAdmin();

        $res = Wallet::credit($user, 'coins', 5, 'gift', [
            'reference_type' => $admin->getMorphClass(),
            'reference_id'   => $admin->getKey(),
        ]);

        $tx = WalletTransaction::find($res->transactionId);
        $this->assertTrue($tx->reference->is($admin)); // polymorphic resolve
    }

    public function test_ledger_reference_is_null_when_meta_omits_it(): void
    {
        $user = User::factory()->create();
        $res = Wallet::credit($user, 'coins', 5, 'gift');

        $tx = WalletTransaction::find($res->transactionId);
        $this->assertNull($tx->reference_type);
        $this->assertNull($tx->reference);
    }

    // ----------------------------------------------------------------------
    // ChargeService — multi-currency + currency isolation + reason passthrough
    // ----------------------------------------------------------------------

    public function test_charge_in_a_non_coin_currency_updates_only_that_wallet(): void
    {
        config(['wallet.currencies' => ['coins', 'diamonds']]);
        $user = User::factory()->create();

        $charge = app(ChargeService::class)->charge($user, 50, 'charge', null, 'event', 'diamonds', 9.5);

        $this->assertSame('diamonds', $charge->currency);
        $this->assertEquals(50.0, Wallet::getBalance($user, 'diamonds'));
        $this->assertSame(0.0, Wallet::getBalance($user, 'coins')); // coins untouched
        $this->assertEquals(9.5, (float) $charge->usd);             // decimal:3 usd cast
        $this->assertSame('event', $charge->reason);
    }

    public function test_charge_records_before_and_after_balance(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');

        $charge = app(ChargeService::class)->charge($user, 40, 'charge');

        $this->assertEquals(100.0, (float) $charge->balance_before);
        $this->assertEquals(140.0, (float) $charge->balance_after);
    }

    public function test_charge_with_custom_morph_charger_records_its_class(): void
    {
        $user = User::factory()->create();
        $charger = $this->makeAdmin();

        $charge = app(ChargeService::class)->charge($user, 10, 'charge', $charger);

        $this->assertSame($charger->getMorphClass(), $charge->charger_type);
        $this->assertSame($charger->getKey(), (int) $charge->charger_id);
        $this->assertTrue($charge->charger->is($charger));
    }

    public function test_deduct_links_a_negative_ledger_row(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');

        $charge = app(ChargeService::class)->charge($user, 30, 'deduct');

        $this->assertEquals(-30.0, (float) $charge->amount);
        $this->assertSame('-30.00', $charge->walletTransaction->amount); // signed ledger row
        $this->assertEquals(70.0, Wallet::getBalance($user, 'coins'));
    }

    // ----------------------------------------------------------------------
    // Charge model — i18n + invoice + boolean cast (untested fields)
    // ----------------------------------------------------------------------

    public function test_charge_model_persists_i18n_invoice_and_boolean_cast(): void
    {
        $user = User::factory()->create();
        $charge = Charge::create([
            'target_type'         => $user->getMorphClass(),
            'target_id'           => $user->getKey(),
            'currency'            => 'coins',
            'amount'              => 10,
            'balance_before'      => 0,
            'balance_after'       => 10,
            'reason_en'           => 'Welcome bonus',
            'reason_ar'           => 'مكافأة ترحيب',
            'invoice'             => 'invoices/abc.pdf',
            'is_used_transferred' => 1,
            'meta'                => ['source' => 'admin'],
        ]);

        $fresh = $charge->fresh();
        $this->assertSame('Welcome bonus', $fresh->reason_en);
        $this->assertSame('مكافأة ترحيب', $fresh->reason_ar);
        $this->assertSame('invoices/abc.pdf', $fresh->invoice);
        $this->assertTrue($fresh->is_used_transferred);     // boolean cast
        $this->assertSame(['source' => 'admin'], $fresh->meta); // array cast
    }

    // ----------------------------------------------------------------------
    // CoinLog status casts + PaymentCoin scope chaining
    // ----------------------------------------------------------------------

    public function test_coin_log_status_casts_to_integer(): void
    {
        $user = User::factory()->create();
        $log = CoinLog::create([
            'user_id' => $user->id, 'paid_usd' => '4.99', 'obtained_coins' => '500', 'status' => '0',
        ]);

        $fresh = $log->fresh();
        $this->assertSame(0, $fresh->status);          // int cast
        $this->assertSame(500, $fresh->obtained_coins);
        $this->assertSame(4.99, $fresh->paid_usd);     // float cast
        $this->assertTrue($fresh->user->is($user));
    }

    public function test_payment_coin_active_scope_chains_and_excludes_inactive(): void
    {
        // unique(type, package_type) → vary the package_type to keep rows distinct.
        PaymentCoin::create(['title' => 'On', 'status' => true, 'type' => 'card', 'package_type' => 'user']);
        PaymentCoin::create(['title' => 'Off', 'status' => false, 'type' => 'card', 'package_type' => 'shipping_agency']);
        PaymentCoin::create(['title' => 'OnWallet', 'status' => true, 'type' => 'wallet', 'package_type' => 'user']);

        $this->assertSame(2, PaymentCoin::active()->count());                       // only active
        $this->assertSame(1, PaymentCoin::where('type', 'card')->active()->count()); // chains with other wheres
    }

    // ----------------------------------------------------------------------
    // NullWallet — write throws, reads safe (fallback when wallet disabled)
    // ----------------------------------------------------------------------

    public function test_null_wallet_reads_are_safe(): void
    {
        $null = new NullWallet();
        $user = User::factory()->create();

        $this->assertFalse($null->isAvailable());
        $this->assertSame(0.0, $null->getBalance($user, 'coins'));
        $this->assertFalse($null->canAfford($user, 'coins', 1));
    }

    public function test_null_wallet_credit_throws(): void
    {
        $this->expectException(WalletProviderMissingException::class);
        (new NullWallet())->credit(User::factory()->create(), 'coins', 10, 'gift');
    }

    public function test_null_wallet_debit_throws(): void
    {
        $this->expectException(WalletProviderMissingException::class);
        (new NullWallet())->debit(User::factory()->create(), 'coins', 10, 'gift');
    }

    public function test_null_wallet_satisfies_the_contract(): void
    {
        $this->assertInstanceOf(WalletContract::class, new NullWallet());
    }

    // ----------------------------------------------------------------------
    // WalletResult DTO
    // ----------------------------------------------------------------------

    public function test_wallet_result_to_array_includes_all_fields_with_null_tx(): void
    {
        $result = new WalletResult(
            success: true, currency: 'coins', amount: 10.0, balance: 90.0,
            reason: 'gift', transactionId: null, meta: ['k' => 'v'],
        );

        $this->assertSame([
            'success'        => true,
            'currency'       => 'coins',
            'amount'         => 10.0,
            'balance'        => 90.0,
            'reason'         => 'gift',
            'transaction_id' => null,    // null kept, not omitted
            'meta'           => ['k' => 'v'],
        ], $result->toArray());
    }

    // ----------------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------------

    /** A real persisted non-User morphable model to exercise polymorphic columns. */
    private function makeAdmin(): \App\Models\AdminUser
    {
        static $n = 0;
        $n++;

        return \App\Models\AdminUser::create([
            'name'     => 'Admin ' . $n,
            'email'    => "admin{$n}@example.com",
            'password' => 'secret',
        ]);
    }
}
