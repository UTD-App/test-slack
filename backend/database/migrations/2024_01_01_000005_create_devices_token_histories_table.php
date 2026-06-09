<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices_token_histories', function (Blueprint $table) {
            $table->id();
            $table->string('device_token');
            $table->integer('count')->default(0);
            $table->timestamps();

            $table->index('device_token');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devices_token_histories');
    }
};
