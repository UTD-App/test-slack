<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('room_boom_levels', function (Blueprint $table) {
            $table->id();
            $table->tinyInteger('level');
            $table->bigInteger('min_target');
            $table->bigInteger('target');
            $table->string('video')->nullable();
            $table->string('image_type')->nullable();
            $table->string('background_image')->nullable();
            $table->string('image_type_background')->nullable();
            $table->string('boom_image')->nullable();
            $table->string('image_type_boom')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_boom_levels');
    }
};
