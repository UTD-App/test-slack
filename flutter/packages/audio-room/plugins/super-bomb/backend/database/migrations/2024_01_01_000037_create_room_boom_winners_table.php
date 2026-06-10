<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('room_boom_winners', function (Blueprint $table) {
            $table->id();
            $table->foreignId('room_boom_reward_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            $table->foreignId('room_boom_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_boom_winners');
    }
};
