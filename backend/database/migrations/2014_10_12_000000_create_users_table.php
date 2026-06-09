<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name')->nullable();
            $table->string('email')->unique()->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('phone')->unique()->nullable();
            $table->string('password')->nullable();
            $table->string('uuid')->unique()->nullable();
            $table->string('firebase_uuid')->nullable();
            $table->unsignedBigInteger('country_id')->nullable();
            $table->string('device_token')->nullable();
            $table->string('avatar')->nullable();
            $table->string('bio')->nullable();
            $table->tinyInteger('gender')->nullable();
            $table->date('birthday')->nullable();
            $table->boolean('status')->default(true);
            $table->boolean('is_points_first')->default(false);
            $table->boolean('is_logout')->default(false);
            $table->integer('profile_count')->default(0);
            $table->timestamp('online_time')->nullable();
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();

            $table->index('phone');
            $table->index('device_token');
            $table->index('country_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
