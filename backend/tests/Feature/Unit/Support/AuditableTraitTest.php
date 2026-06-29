<?php

namespace Tests\Feature;

use App\Models\AdminUser;
use App\Models\Config;
use App\Models\AuditLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Tests\TestCase;

/**
 * The Auditable trait records create/update/delete — but ONLY when an admin is
 * the actor (AuditLogger no-ops otherwise). Config uses the trait, so we exercise
 * it through Config with an authenticated admin guard.
 */
class AuditableTraitTest extends TestCase
{
    use RefreshDatabase;

    private function actingAdmin(): AdminUser
    {
        $admin = AdminUser::create([
            'name' => 'Admin', 'email' => 'a@x.test', 'password' => bcrypt('x'), 'is_active' => true,
        ]);
        Auth::guard('admin')->login($admin);

        return $admin;
    }

    public function test_no_audit_log_written_without_an_admin_actor(): void
    {
        // No login → AuditLogger::actor() is null → log() no-ops.
        Config::create(['name' => 'silent', 'value' => '1']);

        $this->assertDatabaseCount('audit_logs', 0);
    }

    public function test_create_records_an_audit_log_for_admin_actor(): void
    {
        $admin = $this->actingAdmin();

        $config = Config::create(['name' => 'app_name', 'value' => 'Eagle']);

        $log = AuditLog::where('action', 'created')->first();
        $this->assertNotNull($log);
        $this->assertSame($admin->id, $log->admin_user_id);
        $this->assertSame(Config::class, $log->auditable_type);
        $this->assertSame($config->id, $log->auditable_id);
        // Created snapshot keeps name/value, excludes timestamps.
        $this->assertSame('app_name', $log->changes['name']);
        $this->assertSame('Eagle', $log->changes['value']);
        $this->assertArrayNotHasKey('created_at', $log->changes);
        $this->assertArrayNotHasKey('updated_at', $log->changes);
    }

    public function test_update_records_only_the_changed_attributes(): void
    {
        $this->actingAdmin();
        $config = Config::create(['name' => 'app_name', 'value' => 'Old']);
        AuditLog::query()->delete(); // ignore the create entry

        $config->update(['value' => 'New']);

        $log = AuditLog::where('action', 'updated')->first();
        $this->assertNotNull($log);
        $this->assertSame(['value' => 'New'], $log->changes);
    }

    public function test_update_with_no_real_change_writes_no_log(): void
    {
        $this->actingAdmin();
        $config = Config::create(['name' => 'app_name', 'value' => 'Same']);
        AuditLog::query()->delete();

        // Saving the same value → getChanges() empty → updated() skips logging.
        $config->update(['value' => 'Same']);

        $this->assertSame(0, AuditLog::where('action', 'updated')->count());
    }

    public function test_delete_records_an_audit_log_with_empty_changes(): void
    {
        $this->actingAdmin();
        $config = Config::create(['name' => 'app_name', 'value' => 'X']);
        AuditLog::query()->delete();

        $config->delete();

        $log = AuditLog::where('action', 'deleted')->first();
        $this->assertNotNull($log);
        $this->assertNull($log->changes); // empty changes stored as null
    }
}
