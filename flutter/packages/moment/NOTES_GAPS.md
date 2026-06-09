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
| 5 | **Delete ownership** | backend allows any auth user to delete (no owner check) | delete shown for all | backend ownership guard |
| 6 | **Pagination meta** | backend returns a plain array (no last_page) | `hasMore` inferred from empty page | backend pagination meta |
| 7 | **Image upload URLs in dev** | depends on storage disk + `storage:link` | full http URLs (e.g. seeded picsum) work; local-disk paths resolved via `${domain}/storage/...` | finalize storage config |

## Architecture (matches base-project conventions)
- `AppFeature` impl: `lib/core/moment_feature.dart` (registered in host `main.dart` `buildFeatures()`).
- Networking via `BaseApiService` + `ApiClient` (Bearer token auto-attached). No GetIt/DioFactory.
- State: `flutter_bloc` — `MomentFeedBloc` (app-level), `MomentCommentsCubit` / `MomentLikesCubit` (per-moment, created in sheets).
- Nav: `go_router` — feed is a `bottomNav` tab body; `/moment/add` is a route.
- Repository exposed via `Provider<MomentRepository>` for the sheets.
