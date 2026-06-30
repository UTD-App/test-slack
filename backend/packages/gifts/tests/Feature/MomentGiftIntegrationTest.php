<?php

namespace Utd\Gifts\Tests\Feature;

use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftLog;
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

    public function test_feed_reports_batched_gift_count_and_coins(): void
    {
        // Exercises the N+1 fix: the feed pre-computes gifts_count/gifts_coins for
        // the whole page via GiftDirectory::statsFor (one query), and MomentResource
        // reads the pre-computed values instead of querying per moment. The gift
        // aggregate is seeded directly so the owner's feed fetch is the only HTTP
        // request (a second different-user request in one test trips a Sanctum
        // test-resolution artifact, not a production issue).
        $sender = User::factory()->create();
        $owner  = User::factory()->create();
        $gift   = Gift::create(['name' => 'Rose', 'e_name' => 'Rose', 'type' => 1, 'price' => 100, 'enable' => true]);
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'hi']);

        // Two gift_logs for this moment → count 2 (1+1), coins 200 (120+80).
        foreach ([['num' => 1, 'price' => 120], ['num' => 1, 'price' => 80]] as $row) {
            GiftLog::create([
                'gift_id'      => $gift->id,
                'gift_name'    => 'Rose',
                'sender_id'    => $sender->id,
                'receiver_id'  => $owner->id,
                'gift_num'     => $row['num'],
                'total_price'  => $row['price'],
                'context_type' => 'moment',
                'context_id'   => $moment->id,
            ]);
        }

        $oToken = $owner->createToken('t')->plainTextToken;
        $this->withHeader('Authorization', "Bearer {$oToken}")
            ->getJson('/api/moment?type=4')
            ->assertStatus(200)
            ->assertJsonPath('data.0.id', $moment->id)
            ->assertJsonPath('data.0.gifts_count', 2)
            ->assertJsonPath('data.0.gifts_coins', 200);
    }
}
