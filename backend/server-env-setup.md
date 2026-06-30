# Server Environment Setup - UTD Stream Token Endpoint

## What changed
The backend now proxies token requests to UTD Stream Engine instead of exposing the server secret to the mobile app.

## What's needed
Add these 3 variables to the `.env` file on the production server (`project-x.utdsoftware.com`):

```
UTD_STREAM_APP_ID=4602085317
UTD_STREAM_SERVER_SECRET=ed3ef954a7cae8e18879feeb73c7fac5
UTD_STREAM_ENGINE_URL=https://engine.udt-stream.com
```

## After adding them
Run this command on the server:

```bash
php artisan config:clear
```

## How to verify
Call this endpoint from the browser or Postman:

```
POST https://project-x.utdsoftware.com/api/rooms/{any_room_id}/token
Authorization: Bearer {user_token}
Content-Type: application/json

{
  "identity": "11",
  "service": "rooms"
}
```

Expected: 200 response with a token object.
If you get "Missing X-App-Id or X-App-Secret header" → the env vars are not set correctly.
