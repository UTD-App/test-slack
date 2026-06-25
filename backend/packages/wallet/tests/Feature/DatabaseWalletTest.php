<?php

namespace Utd\Wallet\Tests\Feature;

use App\Events\Wallet\WalletCredited;
use App\Events\Wallet\WalletDebited;
use App\Exceptions\InsufficientFundsException;
use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use InvalidArgumentException;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;
use Utd\Wallet\Models\UserWallet;
use Utd\Wallet\Models\WalletTransaction;

/**
 * The coin engine: DatabaseWallet (bound to the Base WalletContract / Wallet facade).
 * Every credit/debit is row-locked, balance-checked, ledgered and announced.
 */
class DatabaseWalletTest extends TestCase
{
    use RefreshDatabase;

    public function test_provider_reports_wallet_available(): void
    {
        $this->assertTrue(Wallet::isAvailable());
    }

    public function test_balance_is_zero_when_no_wallet_exists(): void
    {
        $user = User::factory()->create();

        $this->assertSame(0.0, Wallet::getBalance($user, 'coins'));
    }

    public function test_credit_creates_wallet_ledger_and_emits_event(): void
    {
        Event::fake([WalletCredited::class]);
        $user = User::factory()->create();

        $result = Wallet::credit($user, 'coins', 100, 'admin_charge', ['reason' => 'welcome']);

        // WalletResult shape.
        $this->assertTrue($result->success);
        $this->assertSame('coins', $result->currency);
        $this->assertEquals(100.0, $result->amount);
        $this->assertEquals(100.0, $result->balance);
        $this->assertSame('admin_charge', $result->reason);
        $this->assertNotNull($result->transactionId);

        // Balance + wallet row.
        $this->assertEquals(100.0, Wallet::getBalance($user, 'coins'));
        $this->assertSame(1, UserWallet::where('user_id', $user->id)->where('currency', 'coins')->count());

        // Ledger row.
        $tx = WalletTransaction::find($result->transactionId);
        $this->assertSame('coins', $tx->currency);
        $this->assertSame('admin_charge', $tx->type);
        $this->assertEquals(100, (float) $tx->amount);
        $this->assertEquals(0, (float) $tx->balance_before);
        $this->assertEquals(100, (float) $tx->balance_after);
        $this->assertSame('welcome', $tx->meta['reason']);

        Event::assertDispatched(WalletCredited::class, fn (WalletCredited $e) => $e->user->is($user) && (float) $e->amount === 100.0);
    }

    public function test_repeated_credits_reuse_one_wallet_and_accumulate(): void
    {
        $user = User::factory()->create();

        Wallet::credit($user, 'coins', 100, 'admin_charge');
        Wallet::credit($user, 'coins', 50, 'app_charge');

        $this->assertEquals(150.0, Wallet::getBalance($user, 'coins'));
        // One wallet, two ledger rows.
        $this->assertSame(1, UserWallet::where('user_id', $user->id)->where('currency', 'coins')->count());
        $this->assertSame(2, WalletTransaction::where('user_id', $user->id)->count());
    }

    public function test_debit_decreases_balance_logs_negative_and_emits_event(): void
    {
        Event::fake([WalletDebited::class]);
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');

        Wallet::debit($user, 'coins', 30, 'gift');

        $this->assertEquals(70.0, Wallet::getBalance($user, 'coins'));
        $tx = WalletTransaction::where('user_id', $user->id)->where('type', 'gift')->first();
        $this->assertEquals(-30, (float) $tx->amount);
        $this->assertEquals(100, (float) $tx->balance_before);
        $this->assertEquals(70, (float) $tx->balance_after);
        Event::assertDispatched(WalletDebited::class);
    }

    public function test_debit_beyond_balance_throws_and_rolls_back(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 50, 'admin_charge');

        try {
            Wallet::debit($user, 'coins', 80, 'gift');
            $this->fail('Expected InsufficientFundsException');
        } catch (InsufficientFundsException) {
            // expected
        }

        // Balance untouched and no debit ledger row written.
        $this->assertEquals(50.0, Wallet::getBalance($user, 'coins'));
        $this->assertSame(0, WalletTransaction::where('type', 'gift')->count());
    }

    public function test_held_reduces_available_balance(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');
        UserWallet::where('user_id', $user->id)->where('currency', 'coins')->update(['held' => 70]);

        $this->assertTrue(Wallet::canAfford($user, 'coins', 30));
        $this->assertFalse(Wallet::canAfford($user, 'coins', 31));

        $this->expectException(InsufficientFundsException::class);
        Wallet::debit($user, 'coins', 40, 'gift');
    }

    public function test_can_afford_is_false_without_a_wallet(): void
    {
        $user = User::factory()->create();

        $this->assertFalse(Wallet::canAfford($user, 'coins', 1));
    }

    #[DataProvider('nonPositiveAmounts')]
    public function test_credit_rejects_non_positive_amounts(float $amount): void
    {
        $user = User::factory()->create();

        $this->expectException(InvalidArgumentException::class);
        Wallet::credit($user, 'coins', $amount, 'admin_charge');
    }

    #[DataProvider('nonPositiveAmounts')]
    public function test_debit_rejects_non_positive_amounts(float $amount): void
    {
        $user = User::factory()->create();

        $this->expectException(InvalidArgumentException::class);
        Wallet::debit($user, 'coins', $amount, 'gift');
    }

    public static function nonPositiveAmounts(): array
    {
        return ['zero' => [0.0], 'negative' => [-5.0]];
    }

    public function test_unsupported_currency_throws(): void
    {
        // Pin to coins-only regardless of which other packages are installed.
        config(['wallet.currencies' => ['coins']]);
        $user = User::factory()->create();

        $this->expectException(InvalidArgumentException::class);
        Wallet::getBalance($user, 'dollar'); // dollars live in the target package
    }

    public function test_currency_agnostic_each_currency_is_its_own_wallet(): void
    {
        config(['wallet.currencies' => ['coins', 'diamonds']]);
        $user = User::factory()->create();

        Wallet::credit($user, 'coins', 100, 'admin_charge');
        Wallet::credit($user, 'diamonds', 7, 'gift');

        $this->assertEquals(100.0, Wallet::getBalance($user, 'coins'));
        $this->assertEquals(7.0, Wallet::getBalance($user, 'diamonds'));
        $this->assertSame(2, UserWallet::where('user_id', $user->id)->count());
    }

    public function test_idempotency_key_replays_instead_of_double_crediting(): void
    {
        $user = User::factory()->create();

        $first  = Wallet::credit($user, 'coins', 100, 'payment', ['idempotency_key' => 'pay-123']);
        $second = Wallet::credit($user, 'coins', 100, 'payment', ['idempotency_key' => 'pay-123']);

        // Same ledger row replayed — balance moved once, one row written.
        $this->assertSame($first->transactionId, $second->transactionId);
        $this->assertEquals(100.0, $second->balance);
        $this->assertEquals(100.0, Wallet::getBalance($user, 'coins'));
        $this->assertSame(1, WalletTransaction::where('user_id', $user->id)->count());
    }

    public function test_idempotency_key_is_per_operation_not_global(): void
    {
        $user = User::factory()->create();

        Wallet::credit($user, 'coins', 100, 'payment', ['idempotency_key' => 'a']);
        Wallet::credit($user, 'coins', 50, 'payment', ['idempotency_key' => 'b']);

        $this->assertEquals(150.0, Wallet::getBalance($user, 'coins'));
        $this->assertSame(2, WalletTransaction::where('user_id', $user->id)->count());
    }

    public function test_credit_stores_reference_from_meta(): void
    {
        $user = User::factory()->create();
        $source = User::factory()->create();

        $result = Wallet::credit($user, 'coins', 10, 'gift', [
            'reference_type' => User::class,
            'reference_id'   => $source->id,
        ]);

        $tx = WalletTransaction::find($result->transactionId);
        $this->assertSame(User::class, $tx->reference_type);
        $this->assertEquals($source->id, $tx->reference_id);
        $this->assertTrue($tx->reference->is($source));
    }
}
