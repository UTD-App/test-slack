# base-seam — Base-owned integration points the Moment package depends on

These files do **NOT** belong to the `Utd\Moment` package — they live in the
**Base project**. Moment is a *consumer*: it resolves these contracts/facades from
the container. They are shipped here only as a **drop-in reference**: when you
install Moment into a Base that does not already have them, copy them in at the
paths below.

## Where each file goes in the Base

| This repo (base-seam)                                  | Base project path                                       |
| ------------------------------------------------------ | ------------------------------------------------------- |
| `app/Contracts/MediaUploader.php`                      | `app/Contracts/MediaUploader.php`                       |
| `app/Facades/Media.php`                                | `app/Facades/Media.php`                                 |
| `app/Support/Media/MediaResult.php`                    | `app/Support/Media/MediaResult.php`                     |
| `app/Contracts/NotificationSender.php`                 | `app/Contracts/NotificationSender.php`                  |
| `app/Facades/Notify.php`                               | `app/Facades/Notify.php`                                |
| `app/Support/Notifications/NotificationMessage.php`    | `app/Support/Notifications/NotificationMessage.php`     |
| `app/Contracts/ProfileContributor.php`                 | `app/Contracts/ProfileContributor.php`                  |
| `app/Contracts/FollowProvider.php`                     | `app/Contracts/FollowProvider.php`                      |

Namespaces are already `App\…`, so they drop in unchanged.

## What Moment uses them for

- **`MediaUploader` / `Media` facade** → uploading moment images / galleries.
- **`NotificationSender` / `Notify` facade** + `NotificationMessage` → like/comment notifications.
- **`ProfileContributor`** → Moment registers a "my moments" section on the user profile
  (via the Base `ProfileContributorRegistry`).
- **`FollowProvider`** *(optional)* → the "Following" feeds (types 3 & 6) filter by the
  social follow graph. Bound by the **social** package; while unbound the feeds fall
  back to the full feed. Moment checks `app()->bound(FollowProvider::class)` first.

## Optional: gifting on a moment (provided by the **gifts** package)

`POST /api/moment/{id}/gift` resolves `App\Contracts\GiftSender` and reads
aggregations via `App\Contracts\GiftDirectory`. These are owned by the **gifts**
package (see its `base-seam/`). Moment checks `app()->bound(GiftSender::class)` and
returns 503 gracefully when gifts isn't installed — it never hard-depends on them.

> **Keep in sync:** the `Utd\Moment` package is compiled against these signatures.
> If the Base copy diverges, update it here too.
