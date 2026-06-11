<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('room_blacklist', function (Blueprint $table) {
            $table->id();
            $table->foreignId('room_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('banned_by')->nullable();
            $table->timestamp('banned_at')->nullable();
            $table->integer('duration_seconds')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->string('reason')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['room_id', 'user_id']);
            $table->index('expires_at');
            $table->index('is_active');
            $table->foreign('banned_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_blacklist');
    }
};
