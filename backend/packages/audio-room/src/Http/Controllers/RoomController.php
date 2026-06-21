<?php

namespace Utd\AudioRoom\Http\Controllers;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Services\StorageConfigService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Utd\AudioRoom\Entities\Room;
use Utd\AudioRoom\Entities\RoomBlacklist;
use Utd\AudioRoom\Entities\RoomCategory;
use Utd\AudioRoom\Entities\RoomVisitor;

class RoomController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Room::with(['owner.profile', 'owner.country', 'categoryType'])
            ->withCount('visitors')
            ->where('room_status', 1);

        if ($request->filled('category_id')) {
            $query->where('room_type', $request->category_id);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('room_name', 'like', "%{$search}%")
                  ->orWhere('num_id', $search);
            });
        }

        $sortBy = $request->input('sort_by', 'visitors');
        if ($sortBy === 'newest') {
            $query->orderByDesc('created_at');
        } elseif ($sortBy === 'oldest') {
            $query->orderBy('created_at');
        } else {
            $query->orderByDesc('visitors_count')->orderByDesc('created_at');
        }

        $rooms = $query->paginate(20);

        $favorites = json_decode(Auth::user()->room_favorites ?? '[]', true);

        $data = $rooms->getCollection()->map(function ($room) use ($favorites) {
            $formatted = $this->formatRoom($room);
            $formatted['is_favorite'] = in_array($room->id, $favorites);
            return $formatted;
        });

        return Common::apiResponse(true, '', $data, 200, $rooms);
    }

    public function favorites(): JsonResponse
    {
        $favoriteIds = json_decode(Auth::user()->room_favorites ?? '[]', true);

        if (empty($favoriteIds)) {
            return Common::apiResponse(true, '', []);
        }

        $rooms = Room::with(['owner.profile', 'owner.country', 'categoryType'])
            ->withCount('visitors')
            ->whereIn('id', $favoriteIds)
            ->where('room_status', 1)
            ->orderByDesc('visitors_count')
            ->get();

        $data = $rooms->map(function ($room) {
            $formatted = $this->formatRoom($room);
            $formatted['is_favorite'] = true;
            return $formatted;
        });

        return Common::apiResponse(true, '', $data);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'room_name' => 'required|string|max:50',
            'mode' => 'required|integer',
            'room_cover' => 'nullable|image|max:5120',
            'room_intro' => 'nullable|string|max:500',
            'room_type' => 'nullable|integer|exists:room_categories,id',
            'room_class' => 'nullable|integer|exists:room_categories,id',
            'room_pass' => 'nullable|string|max:20',
        ]);

        $existing = Room::where('user_id', Auth::id())->where('type', 'audio')->first();
        if ($existing) {
            return Common::apiResponse(false, 'You already have a room', null, 422);
        }

        $coverPath = null;
        if ($request->hasFile('room_cover')) {
            $coverPath = $request->file('room_cover')->store('rooms/covers');
        }

        $room = Room::create([
            'user_id' => Auth::id(),
            'num_id' => rand(111111, 999999),
            'room_name' => $request->room_name,
            'room_cover' => $coverPath,
            'room_intro' => $request->room_intro,
            'room_type' => $request->room_type,
            'room_class' => $request->room_class,
            'room_pass' => $request->room_pass,
            'mode' => $request->mode,
            'free_mic' => $request->boolean('free_mic', false),
        ]);

        $room->load(['owner.profile', 'owner.country', 'categoryType']);

        return Common::apiResponse(true, 'Room created', $this->formatRoom($room), 201);
    }

    public function show(int $id): JsonResponse
    {
        $room = Room::with(['owner.profile', 'owner.country', 'categoryType'])
            ->withCount('visitors')
            ->findOrFail($id);

        return Common::apiResponse(true, '', $this->formatRoom($room));
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwner(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $request->validate([
            'room_name' => 'nullable|string|max:50',
            'room_intro' => 'nullable|string|max:500',
            'room_rule' => 'nullable|string|max:500',
            'room_cover' => 'nullable|image|max:5120',
            'room_background' => 'nullable|string',
            'room_pass' => 'nullable|string|max:20',
            'mode' => 'nullable|integer',
            'room_type' => 'nullable|integer|exists:room_categories,id',
            'room_class' => 'nullable|integer|exists:room_categories,id',
            'is_comment_closed' => 'nullable|boolean',
            'free_mic' => 'nullable|boolean',
        ]);

        $data = $request->only([
            'room_name', 'room_intro', 'room_rule', 'room_background',
            'room_pass', 'mode', 'room_type', 'room_class',
            'is_comment_closed', 'free_mic',
        ]);

        if ($request->hasFile('room_cover')) {
            if ($room->room_cover) {
                Storage::delete($room->room_cover);
            }
            $data['room_cover'] = $request->file('room_cover')->store('rooms/covers');
        }

        $room->update(array_filter($data, fn ($v) => $v !== null));
        $room->load(['owner.profile', 'owner.country', 'categoryType']);
        $room->loadCount('visitors');

        return Common::apiResponse(true, 'Room updated', $this->formatRoom($room));
    }

    public function destroy(int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwner(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        if ($room->room_cover) {
            Storage::delete($room->room_cover);
        }

        $room->delete();

        return Common::apiResponse(true, 'Room deleted');
    }

    public function enter(Request $request, int $id): JsonResponse
    {
        $room = Room::with(['owner.profile', 'owner.country', 'categoryType'])
            ->withCount('visitors')
            ->findOrFail($id);

        if ($room->room_status !== 1) {
            return Common::apiResponse(false, 'Room is closed', null, 403);
        }

        $ban = RoomBlacklist::where('room_id', $id)
            ->where('user_id', Auth::id())
            ->valid()
            ->first();

        if ($ban) {
            $remaining = $ban->getTimeRemaining();
            return Common::apiResponse(false, 'You are banned from this room', [
                'expires_at' => $ban->expires_at,
                'remaining_seconds' => $remaining,
                'reason' => $ban->reason,
            ], 423);
        }

        if ($room->hasPassword() && !$room->isOwner(Auth::id())) {
            $request->validate(['room_pass' => 'required|string']);
            if ($request->room_pass !== $room->room_pass) {
                return Common::apiResponse(false, 'Wrong password', null, 403);
            }
        }

        RoomVisitor::updateOrCreate(
            ['room_id' => $id, 'user_id' => Auth::id()],
            ['updated_at' => now()]
        );

        $room->loadCount('visitors');

        $streamConfig = [
            'app_id' => config('audio-room.utd_stream.app_id', ''),
            'server_secret' => config('audio-room.utd_stream.server_secret', ''),
        ];

        $favorites = json_decode(Auth::user()->room_favorites ?? '[]', true);

        $roomData = $this->formatRoom($room);
        $roomData['stream_config'] = $streamConfig;
        $roomData['is_owner'] = $room->isOwner(Auth::id());
        $roomData['is_admin'] = $room->isAdmin(Auth::id());
        $roomData['is_favorite'] = in_array($room->id, $favorites);

        return Common::apiResponse(true, '', $roomData);
    }

    public function token(Request $request, int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        $request->validate([
            'identity' => 'required|string',
            'service' => 'required|string',
            'room_owner_id' => 'nullable|string',
            'name' => 'nullable|string',
            'seat_count' => 'nullable|integer',
            'seat_mode' => 'nullable|string',
            'host_seat' => 'nullable|integer',
            'mode_id' => 'nullable|string',
            'metadata' => 'nullable|array',
        ]);

        $user = Auth::user();
        $isOwner = $room->isOwner($user->id);
        $isAdmin = $room->isAdmin($user->id);

        $role = $isOwner ? 'host' : ($isAdmin ? 'admin' : 'audience');

        $payload = [
            'identity' => $request->identity,
            'room_name' => (string) $room->id,
            'service' => $request->service,
            'room_owner_id' => (string) ($request->room_owner_id ?? $room->user_id),
            'role' => $role,
        ];

        if ($request->filled('name')) $payload['name'] = $request->name;
        if ($request->filled('seat_count')) $payload['seat_count'] = $request->seat_count;
        if ($request->filled('seat_mode')) $payload['seat_mode'] = $request->seat_mode;
        if ($request->filled('host_seat')) $payload['host_seat'] = $request->host_seat;
        if ($request->filled('mode_id')) $payload['mode_id'] = $request->mode_id;
        if ($request->filled('metadata')) $payload['metadata'] = $request->metadata;

        $engineBaseUrl = config('audio-room.utd_stream.engine_url', 'https://engine.udt-stream.com');
        $appId = config('audio-room.utd_stream.app_id', '');
        $appSecret = config('audio-room.utd_stream.server_secret', '');

        $response = Http::withHeaders([
            'X-App-Id' => $appId,
            'X-App-Secret' => $appSecret,
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
        ])->post("{$engineBaseUrl}/api/v1/token", $payload);

        if ($response->failed()) {
            return Common::apiResponse(
                false,
                $response->json('message', 'Token generation failed'),
                null,
                $response->status()
            );
        }

        return Common::apiResponse(true, '', $response->json());
    }

    public function streamWebhook(Request $request): JsonResponse
    {
        $secret = $request->header('X-Stream-Secret');
        if ($secret !== config('audio-room.utd_stream.server_secret')) {
            return response()->json(['error' => 'unauthorized'], 401);
        }

        $event = $request->input('event');

        if ($event === 'participant_left') {
            $roomId = $request->input('room.name');
            $userId = $request->input('participant.identity');

            if ($roomId && $userId) {
                RoomVisitor::where('room_id', $roomId)
                    ->where('user_id', $userId)
                    ->delete();
            }
        }

        return response()->json(['ok' => true]);
    }

    public function exit(int $id): JsonResponse
    {
        RoomVisitor::where('room_id', $id)
            ->where('user_id', Auth::id())
            ->delete();

        return Common::apiResponse(true, 'Exited room');
    }

    public function mine(): JsonResponse
    {
        $room = Room::with(['owner.profile', 'owner.country', 'categoryType'])
            ->withCount('visitors')
            ->where('user_id', Auth::id())
            ->where('type', 'audio')
            ->first();

        if (!$room) {
            return Common::apiResponse(true, '', null);
        }

        return Common::apiResponse(true, '', $this->formatRoom($room));
    }

    public function users(int $id): JsonResponse
    {
        $visitors = RoomVisitor::with(['user.profile', 'user.country'])
            ->where('room_id', $id)
            ->paginate(50);

        $data = $visitors->getCollection()->map(function ($visitor) {
            $user = $visitor->user;
            return [
                'id' => $user->id,
                'name' => $user->profile->name ?? $user->name ?? '',
                'avatar' => $user->profile->avatar ?? null,
                'country_flag' => $user->country->flag ?? null,
                'joined_at' => $visitor->created_at,
            ];
        });

        return Common::apiResponse(true, '', $data, 200, $visitors);
    }

    public function toggleFavorite(int $id): JsonResponse
    {
        $user = Auth::user();
        $favorites = json_decode($user->room_favorites ?? '[]', true);

        if (in_array($id, $favorites)) {
            $favorites = array_values(array_diff($favorites, [$id]));
            $isFavorite = false;
        } else {
            $favorites[] = $id;
            $isFavorite = true;
        }

        $user->update(['room_favorites' => json_encode($favorites)]);

        return Common::apiResponse(true, $isFavorite ? 'Added to favorites' : 'Removed from favorites', [
            'is_favorite' => $isFavorite,
        ]);
    }

    public function toggleComments(Request $request, int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $room->update(['is_comment_closed' => $request->boolean('closed', false)]);

        return Common::apiResponse(true, $room->is_comment_closed ? 'Comments closed' : 'Comments opened');
    }

    public function changeMode(Request $request, int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwner(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $request->validate(['mode' => 'required|integer']);
        $room->update(['mode' => $request->mode]);

        return Common::apiResponse(true, 'Mode changed', ['mode' => $room->mode]);
    }

    public function categories(): JsonResponse
    {
        $categories = RoomCategory::where('enable', true)
            ->whereNull('parent_id')
            ->with('children')
            ->orderBy('sort')
            ->get();

        return Common::apiResponse(true, '', $categories);
    }

    public function categoryTypes(int $id): JsonResponse
    {
        $children = RoomCategory::where('parent_id', $id)
            ->where('enable', true)
            ->orderBy('sort')
            ->get();

        return Common::apiResponse(true, '', $children);
    }

    public function removePassword(int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwner(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $room->update(['room_pass' => null]);

        return Common::apiResponse(true, 'Password removed');
    }

    public function muteWriting(Request $request, int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $request->validate(['user_id' => 'required|integer|exists:users,id']);

        return Common::apiResponse(true, 'User muted from writing');
    }

    public function unmuteWriting(Request $request, int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $request->validate(['user_id' => 'required|integer|exists:users,id']);

        return Common::apiResponse(true, 'User unmuted');
    }

    public function sendBanner(Request $request, int $id): JsonResponse
    {
        $room = Room::findOrFail($id);

        if (!$room->isOwnerOrAdmin(Auth::id())) {
            return Common::apiResponse(false, 'Unauthorized', null, 403);
        }

        $request->validate(['message' => 'required|string|max:200']);

        return Common::apiResponse(true, 'Banner sent');
    }

    public function ranking(int $id): JsonResponse
    {
        return Common::apiResponse(true, '', []);
    }

    public function config(): JsonResponse
    {
        return Common::apiResponse(true, '', [
            'app_id' => config('audio-room.utd_stream.app_id', ''),
            'server_secret' => config('audio-room.utd_stream.server_secret', ''),
            'max_admin' => 4,
        ]);
    }

    private function formatRoom(Room $room): array
    {
        $storage = app(StorageConfigService::class);
        $owner = $room->owner;
        $visitorImages = $room->visitors()
            ->with('user.profile')
            ->limit(5)
            ->get()
            ->map(fn ($v) => $v->user->profile->avatar ?? null)
            ->filter()
            ->values()
            ->toArray();

        return [
            'id' => $room->id,
            'num_id' => $room->num_id,
            'owner_id' => $room->user_id,
            'room_name' => $room->room_name,
            'room_cover' => $room->room_cover ? $storage->url($room->room_cover) : null,
            'room_intro' => $room->room_intro,
            'room_rule' => $room->room_rule,
            'room_background' => $room->room_background ? $storage->url($room->room_background) : null,
            'has_password' => $room->hasPassword(),
            'mode' => $room->mode,
            'room_status' => $room->room_status,
            'is_afk' => $room->is_afk,
            'is_comment_closed' => $room->is_comment_closed,
            'free_mic' => $room->free_mic,
            'max_admin' => $room->max_admin,
            'visitor_count' => $room->visitors_count ?? $room->visitors()->count(),
            'visitor_images' => $visitorImages,
            'room_type' => $room->room_type,
            'room_class' => $room->room_class,
            'category_name' => $room->categoryType->name ?? null,
            'owner_name' => $owner?->profile?->name ?? $owner?->name ?? '',
            'owner_avatar' => ($owner?->profile?->avatar) ? $storage->url($owner->profile->avatar) : null,
            'owner_country_flag' => $owner?->country?->flag ?? null,
            'created_at' => $room->created_at,
        ];
    }
}
