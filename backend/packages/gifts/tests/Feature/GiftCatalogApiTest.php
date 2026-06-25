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
}
