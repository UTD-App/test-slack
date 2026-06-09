# Package Development — Backend Guide

How to build a backend package (a Laravel Module) that self-wires into the UTD base.

---

## 1. Anatomy of a package

A package is an `nwidart` Module under `Modules/<Name>/`:

```
Modules/AudioRoom/
├── Providers/AudioRoomServiceProvider.php   ← required, extends BaseModuleServiceProvider
├── Routes/api.php                           ← auto-loaded (prefix: api, middleware: api+localization)
├── Database/Migrations/                     ← auto-loaded by `php artisan migrate`
├── Entities/                                ← models (namespace Modules\AudioRoom\Entities)
├── Resources/lang/                          ← translations (namespace: package slug)
└── Filament/Resources/                      ← admin screens (auto-discovered when enabled)
```

The only required file is the ServiceProvider. Everything else is loaded automatically.

---

## 2. The ServiceProvider (self-wiring)

```php
namespace Modules\AudioRoom\Providers;

use App\Contracts\MenuContributor;
use App\Modules\BaseModuleServiceProvider;

class AudioRoomServiceProvider extends BaseModuleServiceProvider implements MenuContributor
{
    public function packageSlug(): string { return 'audio-room'; }

    public function packageManifest(): array
    {
        return ['name' => 'Audio Room', 'version' => '1.0.0', 'is_core' => false];
    }

    public function roles(): array
    {
        return [['key' => 'audio-room.host', 'display_name' => 'Room Host']]; // app-user roles
    }

    public function settings(): array
    {
        return [['key' => 'audio_room.max_seats', 'type' => 'int', 'default' => 12]];
    }

    // MenuContributor — default menu entries (slug == Flutter UiContribution.contributionId)
    public function getPackage(): string { return $this->packageSlug(); }
    public function getMenuItems(): array
    {
        return [[
            'slug' => 'audio-room.lobby', 'label_key' => 'audio_room.menu_lobby',
            'slot' => 'bottomNav', 'icon' => 'mic', 'order' => 20, 'target' => 'app',
        ]];
    }

    // Override register() to bind a domain contract (see §4):
    // public function register(): void {
    //     parent::register();
    //     $this->app->singleton(\App\Contracts\WalletContract::class, MyWalletService::class);
    // }
}
```

`BaseModuleServiceProvider` auto-loads routes/migrations/translations and registers your
Menu / UserData contributors — **only if the package is enabled**.

> The base reference module is [`Modules/Demo`](../Modules/Demo) — copy it as a starting point.

## 3. Installing / enabling

```bash
composer dump-autoload          # so Modules\<Name>\... autoloads
php artisan migrate             # runs the module's migrations
php artisan utd:sync-packages   # writes the package row + roles + settings + menu defaults
```

Then enable/disable and reorder it from the admin panel → **Packages**. Disabled packages
load nothing (no routes, no admin nav, dropped from the app menu).

---

## 4. Domain contracts (talk to the platform, not to other packages)

Never call another package directly. Use the Base contracts; the right implementation is
resolved from the container.

| Contract | Facade | Base default | Provided by |
|----------|--------|--------------|-------------|
| `App\Contracts\WalletContract` | `Wallet` | `NullWallet` (throws on write) | a Wallet package |
| `App\Contracts\NotificationSender` | `Notify` | Firebase (FCM) | Base (override with SMS/WhatsApp plugins) |
| `App\Contracts\MediaUploader` | `Media` | Storage (admin's driver) | Base (override with an optimizer plugin) |
| `App\Contracts\UserDataContributor` | — | — | every package (adds keys to `/api/my-data`) |

```php
use App\Facades\Wallet;
use App\Facades\Notify;
use App\Facades\Media;
use App\Support\Notifications\NotificationMessage;

if (Wallet::canAfford($user, 'coins', 100)) {
    Wallet::debit($user, 'coins', 100, 'gift:rose');           // throws InsufficientFundsException
}
Notify::send($user, NotificationMessage::make('Gift!', 'You received a rose'));
$result = Media::upload($request->file('avatar'), 'avatars');  // $result->url
```

To **provide** a contract, bind it in your module's `register()` (your binding wins because
module providers register after the Base):

```php
$this->app->singleton(\App\Contracts\WalletContract::class, \Modules\Wallet\Services\WalletService::class);
```

---

## 5. Extending the user (no god-model)

The Base `User` is intentionally minimal. A package adds user-scoped data with its **own table**
and exposes it through a `UserDataContributor` — it does **not** add columns to `users`.

```php
class AudioRoomUserData implements \App\Contracts\UserDataContributor
{
    public function getKey(): string { return 'audio_room'; }
    public function getUserData(\App\Models\User $user): ?array
    {
        return ['hosted_rooms' => $user->hostedRooms()->count()];
    }
}
// register in the module provider's registerCapabilities() / boot:
app(\App\Services\UserDataService::class)->register(new AudioRoomUserData());
```

The contributed array is merged into `GET /api/my-data` under its key. Currency balances
live in the Wallet package (via `WalletContract`), never as columns on `users`.

---

## 6. Admin screens (Filament)

Extend `App\Filament\Resources\BaseResource` so role-gating and nav grouping are consistent:

```php
class RoomResource extends \App\Filament\Resources\BaseResource
{
    protected static ?string $model = \Modules\AudioRoom\Entities\Room::class;
    protected static ?string $navigationGroup = 'Audio Room';   // groups nav per package
    protected static array $accessRoles = ['content_manager'];   // admin_roles; super_admin always allowed
    // form()/table()/getPages() as usual
}
```

Resources under `Modules/<Name>/Filament/Resources` are auto-discovered when the package is
enabled — installing a package adds its dashboard menu automatically.
