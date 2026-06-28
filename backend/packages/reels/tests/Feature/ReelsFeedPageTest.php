<?php

namespace Utd\Reels\Tests\Feature;

use App\Models\AdminRole;
use App\Models\AdminUser;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;
use Utd\Reels\Entities\Real;
use Utd\Reels\Filament\Pages\ReelsFeed;

class ReelsFeedPageTest extends TestCase
{
    use RefreshDatabase;

    private function actingAdmin(): AdminUser
    {
        $admin = AdminUser::create([
            'name' => 'Super', 'email' => 'super@test.dev', 'password' => 'password',
            'is_active' => true,
        ]);
        $role = AdminRole::firstOrCreate(['name' => 'super_admin']);
        $admin->roles()->syncWithoutDetaching([$role->id]);
        $this->actingAs($admin, 'admin');

        return $admin;
    }

    public function test_reels_feed_page_renders(): void
    {
        $this->actingAdmin();
        $u = User::factory()->create();
        Real::create(['user_id' => $u->id, 'url' => 'videos/x.mp4', 'description' => 'hello reel']);

        Livewire::test(ReelsFeed::class)
            ->assertOk()
            ->assertSee('hello reel')
            ->call('next')->assertOk()
            ->call('prev')->assertOk();
    }

    public function test_renders_with_no_reels(): void
    {
        $this->actingAdmin();

        Livewire::test(ReelsFeed::class)->assertOk();
    }

    /**
     * Full-page HTTP GET (exercises the whole Filament layout + panel middleware,
     * unlike Livewire::test which only renders the component). This is what the
     * browser actually loads, so it guards against blank/500 page regressions.
     */
    public function test_full_page_http_get_renders(): void
    {
        $this->actingAdmin();
        $u = User::factory()->create();
        Real::create(['user_id' => $u->id, 'url' => 'https://x/v.mp4', 'description' => 'hello reel']);

        $this->get(ReelsFeed::getUrl())
            ->assertOk()
            ->assertSee('hello reel')
            ->assertSee('<video', false);
    }
}
