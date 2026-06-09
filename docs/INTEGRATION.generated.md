# UTD ⇄ Base Project — Integration (Generated)

> **مولَّد تلقائياً** بـ `php artisan utd:integration-docs` من الـ routes + manifest + الشاشات المدفوعة.
> لا تُعدّله يدوياً — أعِد توليده.

## 1. قنوات التكامل (Routes الفعلية)

| Method | URI | Auth/Middleware |
|---|---|---|
| GET | `admin/stac-screens` | panel:admin, Illuminate\Cookie\Middleware\EncryptCookies, Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse, Illuminate\Session\Middleware\StartSession, Filament\Http\Middleware\AuthenticateSession, Illuminate\View\Middleware\ShareErrorsFromSession, Illuminate\Foundation\Http\Middleware\VerifyCsrfToken, Illuminate\Routing\Middleware\SubstituteBindings, Filament\Http\Middleware\DisableBladeIconComponents, Filament\Http\Middleware\DispatchServingFilamentEvent, App\Http\Middleware\SetAdminLocale, Filament\Http\Middleware\Authenticate |
| GET | `admin/stac-screens/{record}` | panel:admin, Illuminate\Cookie\Middleware\EncryptCookies, Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse, Illuminate\Session\Middleware\StartSession, Filament\Http\Middleware\AuthenticateSession, Illuminate\View\Middleware\ShareErrorsFromSession, Illuminate\Foundation\Http\Middleware\VerifyCsrfToken, Illuminate\Routing\Middleware\SubstituteBindings, Filament\Http\Middleware\DisableBladeIconComponents, Filament\Http\Middleware\DispatchServingFilamentEvent, App\Http\Middleware\SetAdminLocale, Filament\Http\Middleware\Authenticate |
| GET | `api/utd/manifest` | api, localization, utd.secret |
| GET | `api/utd/packages/{key}/sample` | api, localization, utd.secret |
| POST | `api/stac/push` | api, localization |
| GET | `api/stac/packages` | api, localization |
| GET | `api/stac/screens` | api, localization, stac.auth |
| GET | `api/stac` | api, localization |
| GET | `api/stac/{name}/version` | api, localization |
| GET | `api/stac/{name}` | api, localization |

## 2. Manifest — الـ packages وعناصرها (مسجّلة فعلياً)

### 📦 Chat (`chat`)

- Screens: conversations, conversation

| Element | Type | Screen |
|---|---|---|
| `name` | string | conversations |
| `image` | image_url | conversations |
| `last_message` | string | conversations |
| `unread_count` | int | conversations |
| `time` | datetime | conversations |
| `text` | string | conversation |
| `is_mine` | bool | conversation |
| `sender_name` | string | conversation |
| `sender_avatar` | image_url | conversation |
| `time` | datetime | conversation |
| `attachment_url` | image_url | conversation |

**Action elements:** `text_message` (text), `voice_message` (audio), `image_message` (image)

## 3. الشاشات المدفوعة + توافق الـ Rendering

| Screen | Package | Version | Active | أنواع غير مدعومة |
|---|---|---|---|---|
| `chat.conversations` | chat | 1.0.0 | ✓ | ✅ — |

> ⚠️ نوع غير مدعوم = الـ Flutter لن يرسمه. أضِف parser مخصص أو عدّل التصميم.
