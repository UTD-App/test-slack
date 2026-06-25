<?php

namespace Utd\Gifts\Tests\Feature;

use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;
use Utd\Moment\Entities\Moment;

/**
 * End-to-end: installing Gifts lights up Moment gifting. The Moment route
 * (POST /api/moment/{id}/gift) resolves GiftSender and now succeeds (was 503).
 */
class MomentGiftIntegrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_sending_a_gift_on_a_moment_works_and_aggregates(): void
    {
        $sender = User::factory()->create();
        $owner  = User::factory()->create();
        Wallet::credit($sender, 'coins', 1000, 'admin_charge');
        $gift   = Gift::create(['name' => 'Rose', 'e_name' => 'Rose', 'type' => 1, 'price' => 100, 'enable' => true]);
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'hi']);
        $token  = $sender->createToken('t')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/gift", ['gift_id' => $gift->id, 'num' => 1])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertEquals(900.0, Wallet::getBalance($sender, 'coins'));
        $this->assertEquals(100.0, Wallet::getBalance($owner, 'diamonds'));

        // Aggregation served by the Gifts package (GiftDirectory).
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moments/{$moment->id}/gifts")
            ->assertStatus(200)
            ->assertJsonPath('data.0.num', 1)
            ->assertJsonPath('data.0.gift_id', $gift->id);
    }
}
