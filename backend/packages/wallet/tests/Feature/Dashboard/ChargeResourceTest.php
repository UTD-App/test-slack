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
use Utd\Wallet\Filament\Resources\ChargeResource;
use Utd\Wallet\Filament\Resources\ChargeResource\Pages\CreateCharge;
use Utd\Wallet\Models\Charge;

/**
 * The dashboard "Charge a user" page (Filament). Drives the real CreateCharge
 * page → ChargeService → Wallet, exactly as an admin would.
 */
class ChargeResourceTest extends TestCase
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

    public function test_resource_is_read_only_except_creating(): void
    {
        $this->assertFalse(ChargeResource::canEdit(new Charge()));
        $this->assertFalse(ChargeResource::canDelete(new Charge()));
    }

    public function test_super_admin_can_access_but_a_roleless_admin_cannot(): void
    {
        $this->assertTrue(ChargeResource::canAccess());

        $stranger = AdminUser::create(['name' => 'No', 'email' => 'no@test.com', 'password' => 'secret']);
        $this->actingAs($stranger, 'admin');
        $this->assertFalse(ChargeResource::canAccess());
    }

    public function test_admin_can_charge_a_user(): void
    {
        $user = User::factory()->create();

        Livewire::test(CreateCharge::class)
            ->fillForm([
                'user_id'   => $user->id,
                'currency'  => 'coins',
                'direction' => 'charge',
                'amount'    => 500,
                'reason'    => 'welcome bonus',
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertEquals(500.0, Wallet::getBalance($user, 'coins'));
        $this->assertDatabaseHas('charges', [
            'target_id' => $user->id,
            'currency'  => 'coins',
            'amount'    => 500,
            'reason'    => 'welcome bonus',
        ]);
    }

    public function test_admin_can_deduct_from_a_user(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 300, 'admin_charge');

        Livewire::test(CreateCharge::class)
            ->fillForm([
                'user_id'   => $user->id,
                'currency'  => 'coins',
                'direction' => 'deduct',
                'amount'    => 100,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertEquals(200.0, Wallet::getBalance($user, 'coins'));
    }

    public function test_deducting_more_than_balance_is_blocked(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 50, 'admin_charge');

        Livewire::test(CreateCharge::class)
            ->fillForm([
                'user_id'   => $user->id,
                'currency'  => 'coins',
                'direction' => 'deduct',
                'amount'    => 80,
            ])
            ->call('create')
            ->assertNotified();

        // Balance untouched and no charge persisted (the whole op halts).
        $this->assertEquals(50.0, Wallet::getBalance($user, 'coins'));
        $this->assertDatabaseMissing('charges', ['target_id' => $user->id, 'amount' => -80]);
    }

    public function test_create_requires_a_target_and_amount(): void
    {
        Livewire::test(CreateCharge::class)
            ->fillForm(['user_id' => null, 'amount' => null])
            ->call('create')
            ->assertHasFormErrors(['user_id', 'amount']);
    }
}
