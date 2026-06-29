<?php

namespace Tests\Feature\Unit\Events;

use App\Events\Wallet\WalletCredited;
use App\Events\Wallet\WalletDebited;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WalletEventsTest extends TestCase
{
    use RefreshDatabase;

    public function test_wallet_credited_carries_payload(): void
    {
        $user  = User::factory()->create();
        $event = new WalletCredited($user, 'coins', 100.0, 250.0, 'topup', ['ref' => 7]);

        $this->assertSame($user->id, $event->user->id);
        $this->assertSame('coins', $event->currency);
        $this->assertSame(100.0, $event->amount);
        $this->assertSame(250.0, $event->balance);
        $this->assertSame('topup', $event->reason);
        $this->assertSame(['ref' => 7], $event->meta);
    }

    public function test_wallet_debited_carries_payload_and_defaults_meta(): void
    {
        $user  = User::factory()->create();
        $event = new WalletDebited($user, 'diamonds', 30.0, 70.0, 'gift');

        $this->assertSame($user->id, $event->user->id);
        $this->assertSame('diamonds', $event->currency);
        $this->assertSame(30.0, $event->amount);
        $this->assertSame(70.0, $event->balance);
        $this->assertSame('gift', $event->reason);
        $this->assertSame([], $event->meta);
    }
}
