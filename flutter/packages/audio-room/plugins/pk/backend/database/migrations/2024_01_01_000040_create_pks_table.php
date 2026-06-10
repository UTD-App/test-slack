<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pks', function (Blueprint $table) {
            $table->id();
            $table->integer('team_1_boss')->nullable();
            $table->string('team_1')->nullable()->default('0,0,0,0');
            $table->integer('team_2_boss')->nullable();
            $table->string('team_2')->nullable()->default('0,0,0,0');
            $table->integer('judge')->nullable();
            $table->unsignedTinyInteger('status')->nullable()->default(0);
            $table->double('prize_value')->nullable()->default(0);
            $table->unsignedBigInteger('room_id')->nullable()->default(0);
            $table->dateTime('start_at')->nullable();
            $table->dateTime('end_at')->nullable();
            $table->string('winner')->nullable();
            $table->string('title')->nullable();
            $table->string('team_1_title')->nullable();
            $table->string('team_2_title')->nullable();
            $table->text('conditions')->nullable();
            $table->text('team_1_votes')->nullable();
            $table->text('team_2_votes')->nullable();
            $table->string('mics')->nullable()->default('0,0,0,0,0,0,0,0');
            $table->double('t1_score')->nullable()->default(0);
            $table->double('t2_score')->nullable()->default(0);
            $table->unsignedTinyInteger('show_status')->default(0);
            $table->timestamps();

            $table->index('room_id');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pks');
    }
};
