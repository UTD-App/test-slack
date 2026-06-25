<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Idempotent: some assemblies may already carry this table.
        if (Schema::hasTable('moment_comment_likes')) {
            return;
        }

        Schema::create('moment_comment_likes', function (Blueprint $table) {
            // Facebook-style reactions on a comment (or reply). One reaction per
            // user per comment; reaction_type ∈ like/love/haha/wow/sad/angry.
            $table->id();
            $table->foreignId('comment_id')->constrained('moment_user_comments')->cascadeOnDelete();
            $table->unsignedBigInteger('user_id');
            $table->string('reaction_type')->default('like');
            $table->timestamps();

            $table->unique(['comment_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('moment_comment_likes');
    }
};
