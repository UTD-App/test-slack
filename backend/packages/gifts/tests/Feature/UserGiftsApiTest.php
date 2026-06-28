<?php

namespace Utd\Gifts\Tests\Feature;

use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;

class UserGiftsApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    public function test_user_gifts_returns_only_affordable_gifts_paginated(): void
    {
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 150, 'admin_charge');
        Gift::create(['name' => 'Cheap', 'type' => 1, 'price' => 100, 'enable' => true]);
        Gift::create(['name' => 'Pricey', 'type' => 1, 'price' => 200, 'enable' => true]);

        $this->authed($user)->getJson('/api/user-gifts')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data.data')          // paginator → data.data
            ->assertJsonPath('data.data.0.name', 'Cheap')
            ->assertJsonPath('data.total', 1)
            ->assertJsonPath('data.current_page', 1);
    }

    public function test_user_gifts_with_no_balance_returns_only_free_gifts(): void
    {
        $user = User::factory()->create(); // no credit → balance 0
        Gift::create(['name' => 'Free', 'type' => 1, 'price' => 0, 'enable' => true]);
        Gift::create(['name' => 'Paid', 'type' => 1, 'price' => 100, 'enable' => true]);

        $this->authed($user)->getJson('/api/user-gifts')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.name', 'Free');
    }

    public function test_user_gifts_is_safe_when_new_gift_column_absent(): void
    {
        // The base User has no `new_gift` column → markGiftsSeen() is a no-op, no error.
        $user = User::factory()->create();
        Wallet::credit($user, 'coins', 50, 'admin_charge');

        $this->authed($user)->getJson('/api/user-gifts')->assertStatus(200);
    }

    private function authed(User $user): self
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('t')->plainTextToken);
    }
}
