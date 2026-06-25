<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Sender/receiver LEVEL definitions (badges). A user's level is the highest row of
 * its `kind` whose `threshold` (required EXP) is <= the user's accumulated gift EXP
 * — sender EXP from coins spent, receiver EXP from diamonds earned (stored in
 * gift_user_exp). These are pure badges (icon + number on the profile); no gift is
 * tied to a level.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('gift_levels', function (Blueprint $table) {
            $table->id();
            $table->string('kind');                    // sender | receiver
            $table->unsignedInteger('level');          // 1, 2, 3 …
            $table->unsignedBigInteger('threshold');   // required accumulated EXP
            $table->json('title');                     // {"en":"Bronze","ar":"برونزي"}
            $table->string('img')->nullable();         // badge icon (path or URL; svga ok)
            $table->string('color')->nullable();       // optional badge color
            $table->timestamps();

            $table->unique(['kind', 'level']);
            $table->index(['kind', 'threshold']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gift_levels');
    }
};
