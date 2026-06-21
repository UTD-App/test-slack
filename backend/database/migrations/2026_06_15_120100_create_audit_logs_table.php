<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_user_id')->nullable()->index();   // who (admin actor)
            $table->string('action');                                  // created | updated | deleted | <custom>
            $table->string('auditable_type')->nullable();              // model class
            $table->unsignedBigInteger('auditable_id')->nullable();    // model id
            $table->string('description')->nullable();
            $table->json('changes')->nullable();                       // changed attributes
            $table->string('ip', 45)->nullable();
            $table->string('user_agent', 512)->nullable();
            $table->timestamps();

            $table->index(['auditable_type', 'auditable_id']);
            $table->index('action');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};
