<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_roles', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('label');
            $table->timestamps();
        });

        Schema::create('admin_role_user', function (Blueprint $table) {
            $table->foreignId('admin_user_id')->constrained('admin_users')->cascadeOnDelete();
            $table->foreignId('admin_role_id')->constrained('admin_roles')->cascadeOnDelete();
            $table->primary(['admin_user_id', 'admin_role_id']);
        });

        // Seed default roles
        \DB::table('admin_roles')->insert([
            ['name' => 'super_admin',   'label' => 'Super Admin',   'created_at' => now(), 'updated_at' => now()],
            ['name' => 'user_manager',  'label' => 'User Manager',  'created_at' => now(), 'updated_at' => now()],
            ['name' => 'content_manager','label' => 'Content Manager','created_at' => now(), 'updated_at' => now()],
            ['name' => 'settings_manager','label' => 'Settings Manager','created_at' => now(), 'updated_at' => now()],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_role_user');
        Schema::dropIfExists('admin_roles');
    }
};
