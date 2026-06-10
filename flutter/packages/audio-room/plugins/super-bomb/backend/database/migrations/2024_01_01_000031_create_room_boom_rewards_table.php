<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('room_boom_rewards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('room_boom_level_id')->constrained()->cascadeOnUpdate()->cascadeOnDelete();
            $table->string('target');
            $table->string('target_type');
            $table->tinyInteger('priority');
            $table->integer('quantity');
            $table->integer('expire_days')->nullable()->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_boom_rewards');
    }
};
