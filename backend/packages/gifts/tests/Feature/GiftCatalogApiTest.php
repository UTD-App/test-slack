<?php

namespace Utd\Gifts\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftCategory;

class GiftCatalogApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush(); // catalog is cached — avoid cross-test bleed
    }

    public function test_categories_endpoint_returns_localized_titles(): void
    {
        $user = User::factory()->create();
        GiftCategory::create(['title' => ['en' => 'Popular', 'ar' => 'الأكثر'], 'type' => 'normal', 'sort' => 1]);
        $token = $user->createToken('t')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/gifts/categories')
            ->assertStatus(200)
            ->assertJsonPath('data.0.title', 'Popular')
            ->assertJsonPath('data.0.type', 'normal');
    }

    public function test_gifts_endpoint_returns_only_enabled_gifts_for_category(): void
    {
        $user = User::factory()->create();
        $cat  = GiftCategory::create(['title' => ['en' => 'Popular'], 'type' => 'normal', 'sort' => 1]);
        Gift::create(['name' => 'Rose', 'e_name' => 'Rose', 'type' => 1, 'gift_category_id' => $cat->id, 'price' => 10, 'enable' => true]);
        Gift::create(['name' => 'Off', 'e_name' => 'Off', 'type' => 1, 'gift_category_id' => $cat->id, 'price' => 10, 'enable' => false]);
        $token = $user->createToken('t')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/gifts?category_id=' . $cat->id)
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Rose')
            ->assertJsonPath('data.0.price', 10);
    }

    // ----- Eagle-parity endpoints -----

    public function test_images_endpoint_returns_only_enabled_image_urls(): void
    {
        $user = User::factory()->create();
        Gift::create(['name' => 'A', 'type' => 1, 'price' => 10, 'img' => 'gifts/a.png', 'enable' => true]);
        Gift::create(['name' => 'B', 'type' => 1, 'price' => 10, 'img' => 'gifts/b.png', 'enable' => true]);
        Gift::create(['name' => 'Off', 'type' => 1, 'price' => 10, 'img' => 'gifts/off.png', 'enable' => false]);

        $this->authed($user)->getJson('/api/gifts/images')
            ->assertStatus(200)
            ->assertJsonCount(2, 'data');
    }

    public function test_v2_filters_by_category_and_keeps_present_gift_shape(): void
    {
        $user = User::factory()->create();
        $cat  = GiftCategory::create(['title' => ['en' => 'Popular'], 'type' => 'normal', 'sort' => 1]);
        $other = GiftCategory::create(['title' => ['en' => 'Other'], 'type' => 'normal', 'sort' => 2]);
        Gift::create(['name' => 'Rose', 'type' => 1, 'gift_category_id' => $cat->id, 'price' => 10, 'image_type' => 'svga', 'enable' => true]);
        Gift::create(['name' => 'Car', 'type' => 1, 'gift_category_id' => $other->id, 'price' => 10, 'enable' => true]);

        $this->authed($user)->getJson('/api/gifts/v2?type=' . $cat->id)
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Rose')
            ->assertJsonStructure(['data' => [['id', 'name', 'category_id', 'price', 'img', 'show_img', 'image_type', 'vip_level', 'international_gift']]]);
    }

    public function test_v2_backpack_type_minus_one_returns_empty(): void
    {
        $user = User::factory()->create();
        $cat  = GiftCategory::create(['title' => ['en' => 'Popular'], 'type' => 'normal', 'sort' => 1]);
        Gift::create(['name' => 'Rose', 'type' => 1, 'gift_category_id' => $cat->id, 'price' => 10, 'enable' => true]);

        $this->authed($user)->getJson('/api/gifts/v2?type=-1')
            ->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }

    public function test_gift_categories_alias_matches_categories(): void
    {
        $user = User::factory()->create();
        GiftCategory::create(['title' => ['en' => 'Popular', 'ar' => 'الأكثر'], 'type' => 'normal', 'sort' => 1]);

        $this->authed($user)->getJson('/api/gift-categories')
            ->assertStatus(200)
            ->assertJsonPath('data.0.title', 'Popular')
            ->assertJsonPath('data.0.type', 'normal');
    }

    public function test_gifts_by_id_returns_minimal_shape_or_empty(): void
    {
        $user = User::factory()->create();
        $gift = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'show_img' => 'gifts/rose.svga', 'enable' => true]);

        $this->authed($user)->getJson('/api/gifts-by-id?id=' . $gift->id)
            ->assertStatus(200)
            ->assertJsonPath('data.id', $gift->id)
            ->assertJsonPath('data.name', 'Rose');

        $this->authed($user)->getJson('/api/gifts-by-id?id=999999')
            ->assertStatus(200)
            ->assertJsonPath('data', []); // {} decodes to []
    }

    public function test_catalog_is_ordered_by_sort_then_use_count_then_price(): void
    {
        $user = User::factory()->create();
        $cat  = GiftCategory::create(['title' => ['en' => 'C'], 'type' => 'normal', 'sort' => 1]);
        Gift::create(['name' => 'Second', 'type' => 1, 'gift_category_id' => $cat->id, 'price' => 10, 'sort' => 2, 'enable' => true]);
        Gift::create(['name' => 'First', 'type' => 1, 'gift_category_id' => $cat->id, 'price' => 10, 'sort' => 1, 'enable' => true]);

        $this->authed($user)->getJson('/api/gifts/v2?type=' . $cat->id)
            ->assertStatus(200)
            ->assertJsonPath('data.0.name', 'First')
            ->assertJsonPath('data.1.name', 'Second');
    }

    private function authed(User $user): self
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('t')->plainTextToken);
    }
}
