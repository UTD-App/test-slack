<?php

namespace Tests\Feature\Unit;

use App\Exceptions\WalletProviderMissingException;
use App\Models\AdminUser;
use App\Models\AuditLog;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\Wallet\NullWallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Tests\TestCase;

/**
 * AuditLogger only records actions by an authenticated AdminUser (no actor =>
 * no-op), and NullWallet (the no-package default) reads safely but throws on writes.
 */
class AuditLoggerAndWalletTest extends TestCase
{
    use RefreshDatabase;

    private function logger(): AuditLogger
    {
        return app(AuditLogger::class);
    }

    private function admin(): AdminUser
    {
        return AdminUser::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
            'is_active' => true,
        ]);
    }

    // ── AuditLogger ───────────────────────────────────────────────────────────

    public function test_log_is_noop_without_an_actor(): void
    {
        $result = $this->logger()->log('users.ban', null, ['x' => 1]);

        $this->assertNull($result);
        $this->assertDatabaseCount('audit_logs', 0);
    }

    public function test_log_records_when_actor_passed_explicitly(): void
    {
        $admin = $this->admin();
        $subject = User::factory()->create();

        $row = $this->logger()->log('users.ban', $subject, ['reason' => 'spam'], 'Banned user', $admin);

        $this->assertInstanceOf(AuditLog::class, $row);
        $this->assertSame($admin->id, $row->admin_user_id);
        $this->assertSame('users.ban', $row->action);
        $this->assertSame(User::class, $row->auditable_type);
        $this->assertSame($subject->id, $row->auditable_id);
        $this->assertSame('Banned user', $row->description);
        $this->assertSame(['reason' => 'spam'], $row->changes);
    }

    public function test_log_uses_authenticated_admin_guard_as_actor(): void
    {
        $admin = $this->admin();
        Auth::guard('admin')->login($admin);

        $row = $this->logger()->log('settings.update');

        $this->assertNotNull($row);
        $this->assertSame($admin->id, $row->admin_user_id);
    }

    public function test_log_ignores_non_admin_authenticated_user(): void
    {
        // An app User is logged in on the default guard — must NOT be an actor.
        $user = User::factory()->create();
        $this->actingAs($user);

        $this->assertNull($this->logger()->log('users.view'));
        $this->assertDatabaseCount('audit_logs', 0);
    }

    public function test_log_stores_null_changes_when_empty(): void
    {
        $row = $this->logger()->log('thing.done', null, [], null, $this->admin());

        $this->assertNull($row->changes);
    }

    public function test_log_handles_subject_without_id(): void
    {
        $row = $this->logger()->log('misc', new \stdClass(), [], null, $this->admin());

        $this->assertSame(\stdClass::class, $row->auditable_type);
        $this->assertNull($row->auditable_id);
    }

    // ── NullWallet ────────────────────────────────────────────────────────────

    public function test_null_wallet_reads_are_safe(): void
    {
        $wallet = new NullWallet();
        $user = User::factory()->create();

        $this->assertFalse($wallet->isAvailable());
        $this->assertSame(0.0, $wallet->getBalance($user));
        $this->assertFalse($wallet->canAfford($user, 'coins', 10));
    }

    public function test_null_wallet_credit_throws(): void
    {
        $this->expectException(WalletProviderMissingException::class);
        (new NullWallet())->credit(User::factory()->create(), 'coins', 5, 'gift');
    }

    public function test_null_wallet_debit_throws(): void
    {
        $this->expectException(WalletProviderMissingException::class);
        (new NullWallet())->debit(User::factory()->create(), 'coins', 5, 'purchase');
    }
}
