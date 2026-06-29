<?php

namespace Utd\Wallet\Tests\Feature\Dashboard;

use App\Models\AdminUser;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Livewire\Livewire;
use Tests\TestCase;
use Utd\Wallet\Filament\Resources\CoinResource;
use Utd\Wallet\Filament\Resources\CoinResource\Pages\CreateCoin;
use Utd\Wallet\Filament\Resources\PaymentCoinResource;
use Utd\Wallet\Filament\Resources\PaymentCoinResource\Pages\CreatePaymentCoin;
use Utd\Wallet\Models\Coin;
use Utd\Wallet\Models\PaymentCoin;

/**
 * The recharge-catalogue admin (Coin packages + their groups) — previously only
 * manageable via raw DB. Drives the real Filament Create pages as an admin would.
 */
class CoinResourceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
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

    public function test_super_admin_can_access_but_a_roleless_admin_cannot(): void
    {
        $this->assertTrue(CoinResource::canAccess());
        $this->assertTrue(PaymentCoinResource::canAccess());

        $stranger = AdminUser::create(['name' => 'No', 'email' => 'no@test.com', 'password' => 'secret']);
        $this->actingAs($stranger, 'admin');
        $this->assertFalse(CoinResource::canAccess());
        $this->assertFalse(PaymentCoinResource::canAccess());
    }

    public function test_admin_can_create_a_payment_group(): void
    {
        Livewire::test(CreatePaymentCoin::class)
            ->fillForm([
                'title'        => 'Card',
                'package_type' => 'user',
                'status'       => true,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertDatabaseHas('payment_coins', ['title' => 'Card', 'package_type' => 'user']);
    }

    public function test_admin_can_create_a_coin_package_under_a_group(): void
    {
        $group = PaymentCoin::create(['title' => 'Card', 'package_type' => 'user', 'status' => true]);

        Livewire::test(CreateCoin::class)
            ->fillForm([
                'payment_gateway_id' => $group->id,
                'usd'                => 4.99,
                'coin'               => 500,
                'first_charge_coin'  => 100,
                'status'             => true,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertDatabaseHas('coins', [
            'payment_gateway_id' => $group->id,
            'coin'               => 500,
            'first_charge_coin'  => 100,
        ]);
        $this->assertSame(1, $group->coins()->count());
    }

    public function test_coin_create_requires_price_and_amount(): void
    {
        Livewire::test(CreateCoin::class)
            ->fillForm(['usd' => null, 'coin' => null])
            ->call('create')
            ->assertHasFormErrors(['usd', 'coin']);
    }

    public function test_models_relate_group_to_packages(): void
    {
        $group = PaymentCoin::create(['title' => 'Wallet', 'package_type' => 'user', 'status' => true]);
        Coin::create(['payment_gateway_id' => $group->id, 'usd' => 1, 'coin' => 100]);

        $this->assertSame('Wallet', Coin::first()->paymentCoin->title);
        $this->assertTrue(PaymentCoin::active()->whereKey($group->id)->exists());
    }
}
