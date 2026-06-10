<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rooms', function (Blueprint $table) {
            $table->id();
            $table->integer('num_id')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('room_name');
            $table->string('room_cover')->nullable();
            $table->text('room_intro')->nullable();
            $table->text('room_rule')->nullable();
            $table->string('room_background')->nullable();
            $table->string('room_pass')->nullable();
            $table->unsignedBigInteger('room_type')->nullable();
            $table->unsignedBigInteger('room_class')->nullable();
            $table->string('type')->default('audio');
            $table->integer('mode')->default(9);
            $table->tinyInteger('room_status')->default(1);
            $table->boolean('is_afk')->default(false);
            $table->boolean('is_comment_closed')->default(false);
            $table->boolean('free_mic')->default(false);
            $table->integer('max_admin')->default(4);
            $table->timestamps();

            $table->index('user_id');
            $table->index('room_type');
            $table->index('room_status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rooms');
    }
};
