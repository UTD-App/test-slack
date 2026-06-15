<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Granular admin permissions catalog + role↔permission pivot.
 *
 * Sits on top of the existing admin_roles/admin_role_user role system: a role is
 * a BUNDLE of permissions. Permission keys are '<group>.<ability>' (e.g.
 * users.view, users.ban). The catalog is synced by `utd:sync-packages`; grants
 * (which role has which permission) are admin-editable and never auto-reset.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_permissions', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();            // '<group>.<ability>', e.g. users.view
            $table->string('label_key')->nullable();    // i18n key for the display label
            $table->string('group')->index();           // UI grouping = the resource, e.g. 'users'
            $table->string('package')->default('base'); // owning package slug
            $table->timestamps();
        });

        Schema::create('admin_permission_role', function (Blueprint $table) {
            $table->foreignId('admin_role_id')->constrained('admin_roles')->cascadeOnDelete();
            $table->foreignId('admin_permission_id')->constrained('admin_permissions')->cascadeOnDelete();
            $table->primary(['admin_role_id', 'admin_permission_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_permission_role');
        Schema::dropIfExists('admin_permissions');
    }
};
