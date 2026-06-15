<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The user's preferred locale, refreshed from the X-localization header on
 * authenticated requests (see NotificationController::registerDeviceToken).
 * Used to render PUSH notifications in the RECIPIENT's language (the in-app feed
 * renders on read from the request locale, so it doesn't need this). Falls back
 * to config('app.locale') when unset.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('users', 'locale')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('locale', 10)->nullable()->after('device_token');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'locale')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('locale');
            });
        }
    }
};
