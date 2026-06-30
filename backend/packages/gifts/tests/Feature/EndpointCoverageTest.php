<?php

namespace Utd\Gifts\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftLog;

/**
 * Coverage for gifts endpoints not exercised by the other Feature tests:
 *   GET /api/gifts/history
 *   GET /api/gifts/context/{type}/{id}
 *   GET /api/gifts/context/{type}/{id}/gifters
 * plus an auth guard on the route group.
 */
class EndpointCoverageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    private function authed(User $user): self
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('t')->plainTextToken);
    }

    /** Create a gift_logs row in a given context. */
    private function log(array $attrs): GiftLog
    {
        return GiftLog::create(array_merge([
            'gift_id'         => 1,
            'gift_name'       => 'Rose',
            'sender_id'       => 1,
            'receiver_id'     => 2,
            'gift_num'        => 1,
            'total_price'     => 10,
            'receiver_earned' => 10,
        ], $attrs));
    }

    // ----- Auth guard (auth:sanctum) -----

    public function test_endpoints_require_authentication(): void
    {
        $this->getJson('/api/gifts/categories')->assertStatus(401);
        $this->getJson('/api/gifts/history')->assertStatus(401);
        $this->getJson('/api/gifts/context/moment/1')->assertStatus(401);
        $this->getJson('/api/gifts/context/moment/1/gifters')->assertStatus(401);
    }

    // ----- GET /api/gifts/history -----

    public function test_history_defaults_to_received_paginated(): void
    {
        $user   = User::factory()->create();
        $sender = User::factory()->create();
        $gift   = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'enable' => true]);

        // Received by $user.
        $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $user->id, 'gift_num' => 3, 'total_price' => 30]);
        // Sent by $user (must NOT appear in default "received").
        $this->log(['gift_id' => $gift->id, 'sender_id' => $user->id, 'receiver_id' => $sender->id]);

        $this->authed($user)->getJson('/api/gifts/history')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data')                       // items flat under data
            ->assertJsonPath('data.0.direction', 'received')
            ->assertJsonPath('data.0.gift_id', $gift->id)
            ->assertJsonPath('data.0.gift_num', 3)
            ->assertJsonPath('meta.total', 1)                 // pagination at envelope-level meta
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('meta.has_more', false)
            ->assertJsonStructure(['data' => [[
                'id', 'gift_id', 'gift_name', 'gift_num', 'total_price',
                'earned', 'direction', 'context_type', 'context_id', 'created_at',
            ]]]);
    }

    public function test_history_type_sent_returns_only_sent(): void
    {
        $user   = User::factory()->create();
        $other  = User::factory()->create();
        $gift   = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'enable' => true]);

        // Sent by $user (should appear).
        $this->log(['gift_id' => $gift->id, 'sender_id' => $user->id, 'receiver_id' => $other->id]);
        // Received by $user (should NOT appear with type=sent).
        $this->log(['gift_id' => $gift->id, 'sender_id' => $other->id, 'receiver_id' => $user->id]);

        $this->authed($user)->getJson('/api/gifts/history?type=sent')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.direction', 'sent');
    }

    public function test_history_respects_per_page(): void
    {
        $user   = User::factory()->create();
        $sender = User::factory()->create();
        $gift   = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'enable' => true]);

        foreach (range(1, 3) as $i) {
            $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $user->id]);
        }

        $this->authed($user)->getJson('/api/gifts/history?per_page=2')
            ->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('meta.per_page', 2)
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.last_page', 2)
            ->assertJsonPath('meta.has_more', true);
    }

    public function test_history_clamps_excessive_per_page(): void
    {
        // Guards against a row-count DoS: an absurd per_page must be capped at
        // 100 (matches WalletController::transactions), not honoured verbatim.
        $user = User::factory()->create();

        $this->authed($user)->getJson('/api/gifts/history?per_page=1000000')
            ->assertStatus(200)
            ->assertJsonPath('meta.per_page', 100);
    }

    // ----- GET /api/gifts/context/{type}/{id} -----

    public function test_context_gifts_groups_and_sums_for_a_context(): void
    {
        $user   = User::factory()->create();
        $sender = User::factory()->create();
        $gift   = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'img' => 'gifts/rose.png', 'enable' => true]);

        // Same gift, same context → summed.
        $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $user->id, 'gift_num' => 2, 'context_type' => 'moment', 'context_id' => 7]);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $user->id, 'gift_num' => 3, 'context_type' => 'moment', 'context_id' => 7]);
        // Different context → excluded.
        $this->log(['gift_id' => $gift->id, 'sender_id' => $sender->id, 'receiver_id' => $user->id, 'gift_num' => 9, 'context_type' => 'moment', 'context_id' => 8]);

        $this->authed($user)->getJson('/api/gifts/context/moment/7')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.gift_id', $gift->id)
            ->assertJsonPath('data.0.name', 'Rose')
            ->assertJsonPath('data.0.num', 5)
            ->assertJsonStructure(['data' => [['gift_id', 'name', 'img', 'num']]]);
    }

    public function test_context_gifts_empty_context_returns_empty_array(): void
    {
        $user = User::factory()->create();

        $this->authed($user)->getJson('/api/gifts/context/moment/12345')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data', []);
    }

    // ----- GET /api/gifts/context/{type}/{id}/gifters -----

    public function test_context_gifters_groups_by_sender_with_user_shape(): void
    {
        $user = User::factory()->create();
        $g1   = User::factory()->create();
        $g2   = User::factory()->create();
        $gift = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'enable' => true]);

        // g1 gifts 4 in two logs (summed); g2 gifts 1.
        $this->log(['gift_id' => $gift->id, 'sender_id' => $g1->id, 'receiver_id' => $user->id, 'gift_num' => 1, 'context_type' => 'moment', 'context_id' => 7]);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $g1->id, 'receiver_id' => $user->id, 'gift_num' => 3, 'context_type' => 'moment', 'context_id' => 7]);
        $this->log(['gift_id' => $gift->id, 'sender_id' => $g2->id, 'receiver_id' => $user->id, 'gift_num' => 1, 'context_type' => 'moment', 'context_id' => 7]);

        $this->authed($user)->getJson('/api/gifts/context/moment/7/gifters')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(2, 'data')
            // ordered by num desc → g1 (4) first.
            ->assertJsonPath('data.0.user.id', $g1->id)
            ->assertJsonPath('data.0.num', 4)
            ->assertJsonPath('data.1.user.id', $g2->id)
            ->assertJsonPath('data.1.num', 1)
            ->assertJsonStructure(['data' => [['user' => ['id', 'name', 'avatar'], 'num']]]);
    }

    public function test_context_gifters_empty_context_returns_empty_array(): void
    {
        $user = User::factory()->create();

        $this->authed($user)->getJson('/api/gifts/context/moment/12345/gifters')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data', []);
    }
}
