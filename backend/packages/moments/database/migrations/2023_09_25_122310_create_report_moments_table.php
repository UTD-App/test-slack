<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_moments', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('moment_id');
            $table->bigInteger('Reporter_id');
            $table->bigInteger('Reported_id');
            $table->string('description');
            $table->string('type');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_moments');
    }
};
