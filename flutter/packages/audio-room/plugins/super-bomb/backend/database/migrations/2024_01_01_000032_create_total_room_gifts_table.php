<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('total_room_gifts', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('room_id');
            $table->decimal('current_total', 40)->default(0);
            $table->integer('number_of_visitors')->default(0);
            $table->timestamps();

            $table->index('room_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('total_room_gifts');
    }
};
