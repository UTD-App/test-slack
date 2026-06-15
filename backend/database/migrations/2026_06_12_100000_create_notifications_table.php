<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * In-app notification feed. Language-NEUTRAL by design: we store the notification
 * `type` + `params` (translation variables), never rendered text — the title/body
 * are rendered on read in the viewer's locale (see App\Http\Resources\NotificationResource)
 * so changing the UI language re-localizes the whole history. Push messages are
 * rendered at send time in the recipient's stored locale.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('notifications')) {
            return;
        }

        Schema::create('notifications', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('notifiable_type')->default('user');   // 'user' (in-app) | 'admin' (dashboard)
            $table->unsignedBigInteger('notifiable_id');          // recipient id (0 = all admins)
            $table->string('type')->index();                     // e.g. social.follow
            $table->string('category')->nullable()->index();     // social / finance / system …
            $table->json('params')->nullable();                  // translation vars {"name":"Ali"}
            $table->json('data')->nullable();                    // deep-link payload {"user_id":42}
            $table->unsignedBigInteger('actor_id')->nullable();  // who triggered it (avatar)
            $table->string('image_url')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            // unread lookups + feed, scoped by audience
            $table->index(['notifiable_type', 'notifiable_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
