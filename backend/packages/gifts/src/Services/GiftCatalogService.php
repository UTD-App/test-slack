<?php

namespace Utd\Gifts\Services;

use App\Facades\Wallet;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftCategory;
use Utd\Gifts\Support\Media;

/**
 * Reads the gift catalog (categories + gifts) for the API, with light caching.
 */
class GiftCatalogService
{
    /** All categories (ordered), title resolved to the current locale. */
    public function categories(): array
    {
        $ttl = (int) config('gifts.catalog_ttl', 1800);

        return Cache::remember('gifts:categories', $ttl, fn () => GiftCategory::query()
            ->orderBy('sort')
            ->get()
            ->map(fn (GiftCategory $c) => [
                'id'    => $c->id,
                'title' => $this->localize($c->title),
                'type'  => $c->type,
                'sort'  => $c->sort,
            ])
            ->all());
    }

    /** Enabled gifts, optionally filtered by category, in catalog order. */
    public function giftsByCategory(?int $categoryId = null): array
    {
        return $this->orderedCatalog(
            Gift::query()
                ->enabled()
                ->when($categoryId, fn (Builder $q) => $q->where('gift_category_id', $categoryId))
        )
            ->get()
            ->map(fn (Gift $g) => $this->presentGift($g))
            ->all();
    }

    /** Flat list of enabled gift image URLs (Eagle's GET /gifts/images), cached. */
    public function images(): array
    {
        $ttl = (int) config('gifts.catalog_ttl', 1800);

        return Cache::remember('gifts:images', $ttl, fn () => $this->orderedCatalog(Gift::query()->enabled())
            ->pluck('img')
            ->map(fn ($path) => Media::url($path))
            ->filter()
            ->values()
            ->all());
    }

    /** Minimal gift lookup by id (Eagle's GET /gifts-by-id); not enable-filtered. */
    public function byId(int $id): ?array
    {
        $gift = Gift::query()->find($id);

        if (! $gift) {
            return null;
        }

        return [
            'id'    => $gift->id,
            'name'  => $gift->name,
            'image' => Media::url($gift->show_img),
        ];
    }

    /**
     * Enabled gifts the user can currently afford (Eagle's GET /user-gifts:
     * gift price <= the spendable balance), paginated in catalog order. Without
     * the Wallet the balance is 0 → only free gifts (graceful).
     */
    public function affordableGifts(User $user, int $perPage = 10)
    {
        $spend   = (string) config('gifts.spend_currency', 'coins');
        $balance = Wallet::isAvailable() ? Wallet::getBalance($user, $spend) : 0.0;

        return $this->orderedCatalog(Gift::query()->enabled()->where('price', '<=', $balance))
            ->paginate($perPage)
            ->through(fn (Gift $g) => $this->presentGift($g));
    }

    /**
     * Clear the host's "you have a new gift" flag, mirroring Eagle's userGifts().
     * Guarded: the base User may not carry the column, in which case it's a no-op.
     */
    public function markGiftsSeen(User $user): void
    {
        if (Schema::hasColumn($user->getTable(), 'new_gift')) {
            $user->forceFill(['new_gift' => false])->saveQuietly();
        }
    }

    /**
     * The user's owned gifts ("backpack", Eagle's type=-1 branch). The bag lives
     * in a future backpack plugin; App\Contracts\GiftBagProvider only exposes
     * spend hooks (canAfford/debit), not a listing, so return [] until that seam
     * grows a list method. Documented gap, not an error.
     */
    public function backpackGifts(?User $user): array
    {
        return [];
    }

    public function presentGift(Gift $g): array
    {
        return [
            'id'          => $g->id,
            'name'        => $g->name,
            'e_name'      => $g->e_name,
            'type'        => $g->type,
            'category_id' => $g->gift_category_id,
            'price'             => $g->price,
            'img'               => Media::url($g->img),
            'show_img'          => Media::url($g->show_img),
            'show_img2'         => Media::url($g->show_img2),
            'image_type'        => $g->image_type,
            'vip_level'         => $g->vip_level,
            'music_gift'        => $g->music_gift,
            'international_gift' => $g->international_gift,
            'is_play'           => (bool) $g->is_play,
        ];
    }

    /** Eagle's catalog ordering: by sort, then popularity, then price. */
    private function orderedCatalog(Builder $query): Builder
    {
        return $query->orderBy('sort')->orderByDesc('use_count')->orderBy('price');
    }

    /** Pick the current-locale string from a {locale: text} map (fallback en → first). */
    private function localize(mixed $title): string
    {
        if (is_string($title)) {
            return $title;
        }

        if (is_array($title)) {
            return $title[app()->getLocale()] ?? $title['en'] ?? (reset($title) ?: '');
        }

        return '';
    }
}
