<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('room_booms', function (Blueprint $table) {
            $table->id();
            $table->foreignId('total_room_gift_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            $table->foreignId('room_boom_level_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            $table->dateTime('started_at');
            $table->foreignId('trigger_gift_id')->nullable();
            $table->dateTime('ended_at')->nullable();
            $table->foreignId('final_gift_id')->nullable();
            $table->decimal('total_gifts_value', 40)->default(0);
            $table->timestamps();

            $table->unique(['total_room_gift_id', 'room_boom_level_id'], 'unique_roomboom_level');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_booms');
    }
};
