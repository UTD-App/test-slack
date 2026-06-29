# Moment Flutter package — known gaps (to revisit)

Ported from Tempo-Live (`lib/src/features/moment`) into the base-project add-on
platform. Kept **in sync with the simplified backend** (`backend/packages/utd/moment`).
The items below are intentionally deferred until the backend supports them.

| # | Gap | Why | Now | Closed by |
|---|-----|-----|-----|-----------|
| 1 | **Gifts / send-gift / gift rank** | needs Gifts package + currency | omitted from UI | Gifts package + `GiftSender` on backend |
| 2 | **VIP / levels / frames / colored name** | backend `UserResource` simplified | only id, name, avatar, gender, age shown | Levels/VIP packages |
| 3 | **Feed tabs (recommend/latest/follow/my)** | `follow` needs the Follow graph | single feed (`type=4` all) | Follow graph in Base |
| 4 | **Unread chat counts on cards** | from Chat package | omitted | Chat package |
| 5 | ~~Delete ownership~~ ✅ | — | moment delete is author-only (server-enforced); comment delete = author **or** post owner | done |
| 6 | **Pagination meta** | partial — feed reads it, comments & likes don't yet | feed now consumes `meta.has_more`/`last_page` from `Common::apiResponse` (falls back to empty-page inference when meta is absent); comments & likes still infer `hasMore` from an empty page | thread `meta` into comments & likes endpoints/cubits |
| 7 | **Image upload URLs in dev** | depends on storage disk + `storage:link` | full http URLs (e.g. seeded picsum) work; local-disk paths resolved via `${domain}/storage/...` | finalize storage config |

## Added since the port
- **Reactions** (6 types) on posts **and** comments — tap = like, long-press = picker; summary badge.
- **Comments**: one-level replies + reply-to-reply (@mention), per-comment like/react, **load-more pagination**, error/retry, and long-press → report/delete.
- **Likes sheet**: load-more pagination + error/retry.
- **Gifts**: gift counter shows total **coins** (K-formatted), updated instantly on send.
- **Removed** the dead `src/stac/*` integration (it imported base `shared/stac/*` that never existed).

## Architecture (matches base-project conventions)
- `AppFeature` impl: `lib/core/moment_feature.dart` (registered in host `main.dart` `buildFeatures()`).
- Networking via `BaseApiService` + `ApiClient` (Bearer token auto-attached). No GetIt/DioFactory.
- State: `flutter_bloc` — `MomentFeedBloc` (app-level), `MomentCommentsCubit` / `MomentLikesCubit` (per-moment, created in sheets).
- Nav: `go_router` — feed is a `bottomNav` tab body; `/moment/add` is a route.
- Repository exposed via `Provider<MomentRepository>` for the sheets.
