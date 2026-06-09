<?php

namespace App\Providers;

use App\Contracts\MediaUploader;
use App\Contracts\NotificationSender;
use App\Contracts\WalletContract;
use App\Services\Media\StorageMediaUploader;
use App\Services\Notifications\FirebaseNotificationSender;
use App\Services\Wallet\NullWallet;
use Illuminate\Support\ServiceProvider;

/**
 * Binds the Base default implementation for every domain contract.
 *
 * A package overrides a contract by binding its own implementation in its
 * ServiceProvider::register() — package providers register AFTER this one
 * (config/app.php order), so their binding wins.
 *
 * - Notifications: Firebase-backed (Base already ships Firebase).
 * - Media:         Storage-backed (honours the admin's storage driver).
 *
 * Wallet is provided by the Wallet package (WalletServiceProvider) — the Base
 * only ships the WalletContract seam + NullWallet fallback.
 */
class ContractsServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(NotificationSender::class, FirebaseNotificationSender::class);
        $this->app->singleton(MediaUploader::class, StorageMediaUploader::class);
        // Fallback wallet (reads return 0, writes throw). A Wallet package overrides
        // this in its own provider. Without this binding the contract is
        // unresolvable and any gift/economy call 500s instead of degrading.
        $this->app->singleton(WalletContract::class, NullWallet::class);
    }
}
