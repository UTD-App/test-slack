<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('moment', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            // MySQL forbids a DEFAULT on TEXT columns (worked on sqlite, failed on MySQL).
            // Use nullable text; createMoment() always supplies a value (possibly '').
            $table->text('description')->nullable();
            $table->integer('comment_num')->default(0);
            $table->integer('like_num')->default(0);
            $table->string('img')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('moment');
    }
};
