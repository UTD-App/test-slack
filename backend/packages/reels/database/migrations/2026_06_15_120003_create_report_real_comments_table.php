<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('report_real_comments')) {
            return;
        }

        Schema::create('report_real_comments', function (Blueprint $table) {
            // A user report against a specific comment (mirrors report_reals).
            $table->id();
            $table->foreignId('comment_id')->constrained('real_user_comments')->cascadeOnDelete();
            $table->unsignedBigInteger('real_id');
            $table->unsignedBigInteger('Reporter_id');
            $table->unsignedBigInteger('Reported_id');
            $table->string('type');
            $table->text('description');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_real_comments');
    }
};
