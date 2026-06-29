<?php

namespace Tests\Feature\Unit\Events;

use App\Events\Gifts\GiftSent;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GiftSentTest extends TestCase
{
    use RefreshDatabase;

    public function test_carries_sender_receiver_and_amounts(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();

        $event = new GiftSent($sender, $receiver, 5, 3, 300.0, 270.0, ['room' => 'r1']);

        $this->assertSame($sender->id, $event->sender->id);
        $this->assertSame($receiver->id, $event->receiver->id);
        $this->assertSame(5, $event->giftId);
        $this->assertSame(3, $event->quantity);
        $this->assertSame(300.0, $event->total);
        $this->assertSame(270.0, $event->earned);
        $this->assertSame(['room' => 'r1'], $event->context);
    }

    public function test_context_defaults_to_empty_array(): void
    {
        $sender   = User::factory()->create();
        $receiver = User::factory()->create();

        $event = new GiftSent($sender, $receiver, 1, 1, 10.0, 9.0);

        $this->assertSame([], $event->context);
    }
}
