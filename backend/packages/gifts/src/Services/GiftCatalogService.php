<?php

namespace Utd\Gifts\Services;

use Illuminate\Support\Facades\Cache;
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

    /** Enabled gifts, optionally filtered by category, ordered by sort. */
    public function giftsByCategory(?int $categoryId = null): array
    {
        return Gift::query()
            ->enabled()
            ->when($categoryId, fn ($q) => $q->where('gift_category_id', $categoryId))
            ->orderBy('sort')
            ->get()
            ->map(fn (Gift $g) => $this->presentGift($g))
            ->all();
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
        ];
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
