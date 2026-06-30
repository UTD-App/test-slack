# Request: Add receivers ranking endpoint

## What's needed

A new endpoint to return **who received the most gifts** in a given context (room, moment, etc.), similar to the existing `giftersFor()` which returns who **sent** the most.

## Endpoint

```
GET /gifts/context/{type}/{id}/receivers
```

Example: `GET /gifts/context/room/5/receivers`

## Implementation

### 1. Add `receiversFor()` to `GiftDirectory` contract

**File:** `base-seam/app/Contracts/GiftDirectory.php`

```php
/** Who received gifts in a context: [['user' => ['id','name','avatar'], 'num' => int], ...]. */
public function receiversFor(string $type, int $id): array;
```

### 2. Implement in `GiftDirectoryService`

**File:** `src/Services/GiftDirectoryService.php`

Same pattern as `giftersFor()` but grouped by `receiver_id`:

```php
public function receiversFor(string $type, int $id): array
{
    $rows = GiftLog::query()
        ->where('context_type', $type)
        ->where('context_id', $id)
        ->selectRaw('receiver_id, SUM(gift_num) as num')
        ->groupBy('receiver_id')
        ->orderByDesc('num')
        ->get();

    $users = User::query()
        ->whereIn('id', $rows->pluck('receiver_id'))
        ->with('profile')
        ->get(['id', 'name', 'uuid'])
        ->keyBy('id');

    return $rows->map(function ($r) use ($users) {
        $user = $users->get($r->receiver_id);
        return [
            'user' => [
                'id'     => (int) $r->receiver_id,
                'name'   => $user?->name,
                'avatar' => Media::url($user?->avatar),
            ],
            'num' => (int) $r->num,
        ];
    })->all();
}
```

### 3. Add controller method

**File:** `src/Http/Controllers/GiftController.php`

```php
public function contextReceivers(GiftDirectory $directory, string $type, int $id)
{
    return Common::apiResponse(true, 'context_receivers', $directory->receiversFor($type, $id));
}
```

### 4. Add route

**File:** `routes/api.php` (after the gifters route)

```php
Route::get('gifts/context/{type}/{id}/receivers', [GiftController::class, 'contextReceivers']);
```

## Expected response

```json
{
  "success": true,
  "message": "context_receivers",
  "data": [
    {"user": {"id": 5, "name": "Hossam", "avatar": "https://..."}, "num": 42},
    {"user": {"id": 3, "name": "Ahmed", "avatar": "https://..."}, "num": 18}
  ]
}
```

## Why

The audio-room package needs a "Receivers" tab in the room gift ranking sheet to show who received the most gifts inside the room.
