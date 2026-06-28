<?php

namespace Utd\Gifts\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftLog;

class MyGiftsApiTest extends TestCase
{
    use RefreshDatabase;

    private function log(int $receiverId, int $senderId, int $giftId, int $num): void
    {
        GiftLog::create([
            'gift_id'     => $giftId,
            'gift_name'   => 'Rose',
            'sender_id'   => $senderId,
            'receiver_id' => $receiverId,
            'gift_num'    => $num,
            'total_price' => 10 * $num,
        ]);
    }

    public function test_my_gifts_returns_received_grouped_and_summed_for_self(): void
    {
        $user   = User::factory()->create();
        $sender = User::factory()->create();
        $gift   = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'enable' => true]);
        $this->log($user->id, $sender->id, $gift->id, 2);
        $this->log($user->id, $sender->id, $gift->id, 3); // same gift → summed

        $this->authed($user)->getJson('/api/my_gifts')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.gift_id', $gift->id)
            ->assertJsonPath('data.0.num', 5);
    }

    public function test_my_gifts_accepts_explicit_user_id(): void
    {
        $viewer = User::factory()->create();
        $target = User::factory()->create();
        $sender = User::factory()->create();
        $gift   = Gift::create(['name' => 'Rose', 'type' => 1, 'price' => 10, 'enable' => true]);
        $this->log($target->id, $sender->id, $gift->id, 4);

        $this->authed($viewer)->getJson('/api/my_gifts?user_id=' . $target->id)
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.num', 4);
    }

    public function test_my_gifts_unknown_user_id_returns_404(): void
    {
        $user = User::factory()->create();

        $this->authed($user)->getJson('/api/my_gifts?user_id=999999')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    private function authed(User $user): self
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('t')->plainTextToken);
    }
}
