# audio-room — UTD Stream Token Endpoint setup

The audio-room package exposes `POST /api/rooms/{id}/token`, which **proxies** a streaming-token
request to the UTD Stream Engine using a server-side App ID + Secret. The mobile app never holds
the secret — it just calls this endpoint with the user's Bearer (Sanctum) token.

Code path: `routes/api.php` → `RoomController@token` → `Http::post("$engine/api/v1/token")`
with headers `X-App-Id` / `X-App-Secret`. Values come from `config/audio-room.php`
(`utd_stream.app_id|server_secret|engine_url`), which read the env vars below.

## Required environment variables

Add to the project `.env` (NOT committed — secret):

```
UTD_STREAM_APP_ID=4602085317
UTD_STREAM_SERVER_SECRET=<server secret from UTD Stream dashboard>
UTD_STREAM_ENGINE_URL=https://engine.udt-stream.com
```

Then clear the config cache:

```bash
php artisan config:clear
```

The route is gated by `package.enabled:audio-room`, so the `audio-room` package must be enabled
(`php artisan utd:sync-packages`, then enable it in admin → Packages). A disabled package returns
`403 packages.disabled` before the engine is ever called.

## Verify

```
POST {APP_URL}/api/rooms/{any_existing_room_id}/token
Authorization: Bearer {user_token}
Content-Type: application/json

{ "identity": "{user_id}", "service": "rooms" }
```

Expected: `200` with `{ "status": true, "data": { "token", "url", "roomName", "user_token", "ws_url" } }`.

Common failures:
- `403 packages.disabled` → enable the audio-room package.
- `"Missing X-App-Id or X-App-Secret header"` → env vars not set / `config:clear` not run.
- `422 room_name must be alphanumeric ...` → the engine requires `room_name`/`room_owner_id` as
  **strings**; the controller already casts them (`(string) $room->id`). If you see this, confirm
  you are on the fixed `RoomController@token`.

## Production (project-x.utdsoftware.com)

1. Add the three `UTD_STREAM_*` vars (with the real secret) to the server `.env`.
2. `php artisan config:clear`.
3. Verify with the POST above against `https://project-x.utdsoftware.com`.
