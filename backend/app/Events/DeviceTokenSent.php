<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

class DeviceTokenSent implements ShouldBroadcastNow
{
    use InteractsWithSockets;

    public $token;
    public $userId;

    public function __construct($userId, $token)
    {
        $this->userId = $userId;
        $this->token = $token;
    }

    public function broadcastOn()
    {
        return new PresenceChannel('presence.user.' . $this->userId);
    }

    public function broadcastAs()
    {
        return 'device.token.sent';
    }
}
