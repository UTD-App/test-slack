<?php

namespace Utd\Gifts\Tests\Feature;

use App\Contracts\GiftSender;
use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftLevel;
use Utd\Gifts\Services\GiftLevelService;
use Utd\Gifts\Support\GiftSettings;

class GiftExpTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush(); // levels/settings/user-level caches start clean each test
    }

    private function gift(int $price = 100): Gift
    {
        return Gift::create([
            'name'      => 'Rose',
            'e_name'    => 'Rose',
            'type'      => Gift::TYPE_NORMAL,
            'price'     => $price,
            'vip_level' => 0,
            'enable'    => true,
        ]);
    }

    /** Sender + receiver levels at thresholds 0 / 1000 / 10000. */
    private function seedLevels(): void
    {
        foreach ([[1, 0], [2, 1000], [3, 10000]] as [$level, $threshold]) {
            foreach ([GiftLevel::KIND_SENDER, GiftLevel::KIND_RECEIVER] as $kind) {
                GiftLevel::create([
                    'kind'      => $kind,
                    'level'     => $level,
                    'threshold' => $threshold,
                    'title'     => ['en' => "{$kind}-{$level}"],
                ]);
            }
        }
    }

    private function fundedSender(int $coins = 100000): User
    {
        $sender = User::factory()->create();
        Wallet::credit($sender, 'coins', $coins, 'admin_charge');

        return $sender;
    }

    public function test_sending_a_gift_accumulates_sender_and_receiver_exp(): void
    {
        GiftSettings::set('exp_per_coin', 1.0);
        GiftSettings::set('exp_per_diamond', 1.0);

        $sender   = $this->fundedSender();
        $receiver = User::factory()->create();

        app(GiftSender::class)->send($sender, $receiver, $this->gift(100)->id, 2); // value 200

        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $sender->id, 'sender_exp' => 200]);
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $receiver->id, 'receiver_exp' => 200]);
    }

    public function test_exp_rates_scale_the_award(): void
    {
        GiftSettings::set('exp_per_coin', 2.0);    // sender earns double
        GiftSettings::set('exp_per_diamond', 0.5); // receiver earns half

        $sender   = $this->fundedSender();
        $receiver = User::factory()->create();

        app(GiftSender::class)->send($sender, $receiver, $this->gift(100)->id, 2); // value 200

        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $sender->id, 'sender_exp' => 400]);
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $receiver->id, 'receiver_exp' => 100]);
    }

    public function test_level_rises_as_exp_crosses_thresholds(): void
    {
        $this->seedLevels();
        GiftSettings::set('exp_per_coin', 1.0);

        $sender   = $this->fundedSender();
        $receiver = User::factory()->create();
        $gift     = $this->gift(100);

        // 200 exp → still level 1 (< 1000).
        app(GiftSender::class)->send($sender, $receiver, $gift->id, 2);
        $this->assertSame(1, app(GiftLevelService::class)->statsFor($sender->id)['sender_level']);

        // +1000 more (qty 10 → value 1000) → 1200 exp → level 2.
        app(GiftSender::class)->send($sender, $receiver, $gift->id, 10);
        $this->assertSame(2, app(GiftLevelService::class)->statsFor($sender->id)['sender_level']);
    }

    public function test_rate_change_is_not_retroactive(): void
    {
        $sender   = $this->fundedSender();
        $receiver = User::factory()->create();
        $gift     = $this->gift(100);

        GiftSettings::set('exp_per_coin', 1.0);
        app(GiftSender::class)->send($sender, $receiver, $gift->id, 1); // +100 @1.0

        GiftSettings::set('exp_per_coin', 3.0);
        app(GiftSender::class)->send($sender, $receiver, $gift->id, 1); // +300 @3.0

        // Old exp stays banked at the old rate: 100 + 300 = 400 (not 600).
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $sender->id, 'sender_exp' => 400]);
    }

    public function test_batch_send_accumulates_for_each_party(): void
    {
        GiftSettings::set('exp_per_coin', 1.0);
        GiftSettings::set('exp_per_diamond', 1.0);

        $sender = $this->fundedSender();
        $r1     = User::factory()->create();
        $r2     = User::factory()->create();

        // qty 2 @100 to 2 receivers → sender spends 400, each receiver earns 200.
        app(GiftSender::class)->sendMany($sender, [$r1, $r2], $this->gift(100)->id, 2);

        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $sender->id, 'sender_exp' => 400]);
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $r1->id, 'receiver_exp' => 200]);
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $r2->id, 'receiver_exp' => 200]);
    }

    public function test_backfill_command_rebuilds_exp_from_logs(): void
    {
        GiftSettings::set('exp_per_coin', 1.0);
        GiftSettings::set('exp_per_diamond', 1.0);

        $sender   = $this->fundedSender();
        $receiver = User::factory()->create();

        app(GiftSender::class)->send($sender, $receiver, $this->gift(100)->id, 2); // logs value 200

        // Wipe the live exp, then rebuild it from gift_logs.
        \Utd\Gifts\Models\GiftUserExp::query()->delete();
        $this->assertDatabaseCount('gift_user_exp', 0);

        Artisan::call('gifts:backfill-exp');

        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $sender->id, 'sender_exp' => 200]);
        $this->assertDatabaseHas('gift_user_exp', ['user_id' => $receiver->id, 'receiver_exp' => 200]);
    }
}
