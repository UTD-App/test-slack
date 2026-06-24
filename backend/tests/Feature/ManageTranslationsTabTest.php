<?php

namespace Tests\Feature;

use App\Filament\Resources\LanguageResource\Pages\ManageTranslations;
use App\Models\AdminRole;
use App\Models\AdminUser;
use App\Models\Language;
use App\Models\TranslationKey;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

/**
 * Regression: searching the translations table while on the "App" tab used to
 * snap the page back to the "Dashboard" (admin) tab.
 *
 * Cause: the active tab was read from request()->query('tab') on every render.
 * The table search fires a /livewire/update request that carries no query
 * string, so the read fell back to its 'admin' default and the App rows
 * vanished. The tab is now a persisted #[Url] Livewire property (activeTab),
 * so it survives table search / pagination updates.
 */
class ManageTranslationsTabTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Filament page Livewire tests need a current panel + an authed admin.
        Filament::setCurrentPanel(Filament::getPanel('admin'));

        $admin = AdminUser::create([
            'name'      => 'Test Admin',
            'email'     => 'admin@example.test',
            'password'  => bcrypt('secret'),
            'is_active' => true,
        ]);
        // super_admin → Gate::before passes every ability (see AuthServiceProvider).
        // (May already exist from a default-roles migration/seed → firstOrCreate.)
        $role = AdminRole::firstOrCreate(['name' => 'super_admin'], ['label' => 'Super Admin']);
        $admin->roles()->syncWithoutDetaching([$role->id]);

        $this->actingAs($admin, 'admin');
    }

    private function language(): Language
    {
        return Language::create([
            'code'        => 'ar',
            'name'        => 'Arabic',
            'native_name' => 'العربية',
            'is_rtl'      => true,
            'is_active'   => true,
            'is_default'  => false,
        ]);
    }

    public function test_search_on_app_tab_keeps_app_rows_and_hides_admin_rows(): void
    {
        $language = $this->language();

        // Two keys sharing a unique search token, one per tab bucket.
        $appKey   = TranslationKey::create(['key' => 'app.zzqtoken', 'group' => 'app']);
        $adminKey = TranslationKey::create(['key' => 'dashboard.zzqtoken', 'group' => 'dashboard']);

        Livewire::test(ManageTranslations::class, ['record' => $language])
            // User clicked the "App" tab (wire:click $set('activeTab', 'app')).
            ->set('activeTab', 'app')
            // User types into the table search → previously reset the tab.
            ->set('tableSearch', 'zzqtoken')
            ->assertSet('activeTab', 'app')
            ->assertCanSeeTableRecords([$appKey])
            ->assertCanNotSeeTableRecords([$adminKey]);
    }

    public function test_search_on_admin_tab_keeps_admin_rows_and_hides_app_rows(): void
    {
        $language = $this->language();

        $appKey   = TranslationKey::create(['key' => 'app.zzqtoken', 'group' => 'app']);
        $adminKey = TranslationKey::create(['key' => 'dashboard.zzqtoken', 'group' => 'dashboard']);

        // 'admin' is the default tab; assert the inverse so a future change that
        // breaks bucketing the other way is also caught.
        Livewire::test(ManageTranslations::class, ['record' => $language])
            ->set('tableSearch', 'zzqtoken')
            ->assertSet('activeTab', 'admin')
            ->assertCanSeeTableRecords([$adminKey])
            ->assertCanNotSeeTableRecords([$appKey]);
    }
}
