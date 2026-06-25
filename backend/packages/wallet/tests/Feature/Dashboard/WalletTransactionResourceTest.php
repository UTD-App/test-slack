<?php

namespace Utd\Wallet\Tests\Feature\Dashboard;

use App\Facades\Wallet;
use App\Models\AdminUser;
use App\Models\User;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Livewire\Livewire;
use Tests\TestCase;
use Utd\Wallet\Filament\Resources\WalletTransactionResource;
use Utd\Wallet\Filament\Resources\WalletTransactionResource\Pages\ListWalletTransactions;
use Utd\Wallet\Models\WalletTransaction;

/**
 * The dashboard "Wallet Transactions" ledger page (Filament): read-only, and
 * split into Coins / Diamond tabs so currencies never mix.
 */
class WalletTransactionResourceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['wallet.currencies' => ['coins', 'diamonds']]);
        Filament::setCurrentPanel(Filament::getPanel('admin'));
        $this->actingAs($this->superAdmin(), 'admin');
    }

    private function superAdmin(): AdminUser
    {
        $admin  = AdminUser::create(['name' => 'Super', 'email' => 'super@test.com', 'password' => 'secret']);
        $roleId = DB::table('admin_roles')->where('name', 'super_admin')->value('id');
        $admin->roles()->attach($roleId);

        return $admin;
    }

    public function test_resource_is_read_only(): void
    {
        $this->assertFalse(WalletTransactionResource::canCreate());
        $this->assertFalse(WalletTransactionResource::canEdit(new WalletTransaction()));
        $this->assertFalse(WalletTransactionResource::canDelete(new WalletTransaction()));
    }

    public function test_page_exposes_coins_and_diamonds_tabs(): void
    {
        $tabs = (new ListWalletTransactions())->getTabs();

        $this->assertSame(['coins', 'diamonds'], array_keys($tabs));
    }

    public function test_coins_tab_shows_only_coin_movements(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');
        Wallet::credit($user, 'diamonds', 7, 'gift');

        $coinTx    = WalletTransaction::where('currency', 'coins')->get();
        $diamondTx = WalletTransaction::where('currency', 'diamonds')->get();

        Livewire::test(ListWalletTransactions::class)
            // default (first) tab = coins
            ->assertCanSeeTableRecords($coinTx)
            ->assertCanNotSeeTableRecords($diamondTx);
    }

    public function test_diamonds_tab_shows_only_diamond_movements(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 100, 'admin_charge');
        Wallet::credit($user, 'diamonds', 7, 'gift');

        $coinTx    = WalletTransaction::where('currency', 'coins')->get();
        $diamondTx = WalletTransaction::where('currency', 'diamonds')->get();

        Livewire::test(ListWalletTransactions::class)
            ->set('activeTab', 'diamonds')
            ->assertCanSeeTableRecords($diamondTx)
            ->assertCanNotSeeTableRecords($coinTx);
    }
}
