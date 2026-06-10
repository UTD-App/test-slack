<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('room_cup_rewards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('room_cup_target_id')->constrained('room_cup_targets')->cascadeOnDelete();
            $table->string('type');
            $table->string('target');
            $table->integer('expire')->default(1);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_cup_rewards');
    }
};
