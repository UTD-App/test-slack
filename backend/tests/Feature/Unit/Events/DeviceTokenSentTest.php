<?php

namespace Tests\Feature\Unit\Events;

use App\Events\DeviceTokenSent;
use Illuminate\Broadcasting\PresenceChannel;
use Tests\TestCase;

class DeviceTokenSentTest extends TestCase
{
    public function test_payload_and_broadcast_metadata(): void
    {
        $event = new DeviceTokenSent(42, 'fcm-token-abc');

        $this->assertSame(42, $event->userId);
        $this->assertSame('fcm-token-abc', $event->token);
        $this->assertSame('device.token.sent', $event->broadcastAs());

        $channel = $event->broadcastOn();
        $this->assertInstanceOf(PresenceChannel::class, $channel);
        // PresenceChannel name is prefixed with "presence-".
        $this->assertSame('presence-presence.user.42', $channel->name);
    }
}
