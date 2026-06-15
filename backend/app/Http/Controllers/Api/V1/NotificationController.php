<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use App\Models\NotificationPreference;
use Illuminate\Http\Request;

/**
 * In-app notification feed for the authenticated user. List/read/preferences +
 * device-token registration. Titles/bodies are rendered on read in the request
 * locale (X-localization) by {@see NotificationResource}.
 */
class NotificationController extends Controller
{
    /** GET /notifications — paginated feed, newest first, optional ?category= filter. */
    public function index(Request $request)
    {
        $perPage = (int) $request->integer('per_page', (int) config('notifications.per_page', 20));
        $perPage = max(1, min($perPage, 50));

        $page = Notification::query()
            ->forUser($request->user()->id)
            ->when($request->filled('category'), fn ($q) => $q->where('category', $request->string('category')))
            ->with('actor')
            ->latest()
            ->simplePaginate($perPage);

        return Common::apiResponse(true, '', [
            'items'    => NotificationResource::collection($page->items()),
            'page'     => $page->currentPage(),
            'has_more' => $page->hasMorePages(),
        ]);
    }

    /** GET /notifications/unread-count */
    public function unreadCount(Request $request)
    {
        $count = Notification::query()
            ->forUser($request->user()->id)
            ->whereNull('read_at')
            ->count();

        return Common::apiResponse(true, '', ['unread_count' => $count]);
    }

    /** POST /notifications/{id}/read */
    public function markRead(Request $request, int $id)
    {
        Notification::query()
            ->where('id', $id)
            ->forUser($request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return Common::apiResponse(true, __('notifications.marked_read'));
    }

    /** POST /notifications/read-all */
    public function markAllRead(Request $request)
    {
        Notification::query()
            ->forUser($request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return Common::apiResponse(true, __('notifications.marked_all_read'));
    }

    /** PUT /notifications/preferences — mute/unmute a category (optionally per channel). */
    public function updatePreferences(Request $request)
    {
        $data = $request->validate([
            'category' => 'required|string|max:100',
            'channel'  => 'nullable|string|max:50',
            'enabled'  => 'required|boolean',
        ]);

        NotificationPreference::updateOrCreate(
            [
                'user_id'  => $request->user()->id,
                'category' => $data['category'],
                'channel'  => $data['channel'] ?? null,
            ],
            ['enabled' => $data['enabled']],
        );

        return Common::apiResponse(true, __('notifications.preferences_updated'));
    }

    /**
     * POST /notifications/device-token — register/refresh the FCM token AND the
     * user's preferred locale (from X-localization), which is used to render PUSH
     * messages in the recipient's language.
     */
    public function registerDeviceToken(Request $request)
    {
        $data = $request->validate([
            'device_token' => 'required|string|max:512',
        ]);

        $user = $request->user();
        $user->device_token = $data['device_token'];

        $locale = $request->header('X-localization');
        if ($locale && in_array($locale, config('app.supported_locales', ['en', 'ar']), true)) {
            $user->locale = $locale;
        }

        $user->save();

        return Common::apiResponse(true, __('notifications.device_registered'));
    }
}
