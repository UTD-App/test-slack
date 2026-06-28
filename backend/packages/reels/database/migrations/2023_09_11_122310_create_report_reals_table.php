<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_reals', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('real_id');
            $table->bigInteger('Reporter_id');
            $table->bigInteger('Reported_id');
            $table->string('description');
            // `type` is new vs Eagle (parity with the Moment package): the report
            // dialog sends a reason slug (spam/abuse/nudity/violence/other).
            $table->string('type')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_reals');
    }
};
