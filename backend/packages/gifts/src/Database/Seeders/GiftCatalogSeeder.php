<?php

namespace Utd\Gifts\Database\Seeders;

use Illuminate\Database\Seeder;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftCategory;

/**
 * A small starter catalog so the gift picker has content out of the box.
 * Run: php artisan db:seed --class="Utd\\Gifts\\Database\\Seeders\\GiftCatalogSeeder"
 */
class GiftCatalogSeeder extends Seeder
{
    public function run(): void
    {
        // The starter category mirrors the gift TYPE the picker tabs are keyed on:
        // a `normal`-type category must read "Normal/عادية", not "Popular".
        $normal = GiftCategory::updateOrCreate(
            ['type' => 'normal'],
            ['title' => ['en' => 'Normal', 'ar' => 'عادية'], 'sort' => 1],
        );

        // Each starter gift uses a DIFFERENT image format so the picker's
        // DynamicImage renderer is exercised end-to-end: a static raster (png),
        // a vector (svg), an animated raster (gif), and an SVGA animation.
        $gifts = [
            ['name' => 'وردة', 'e_name' => 'Rose', 'price' => 10, 'sort' => 1,
                'image_type' => 'png',
                'img' => 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f339.png'],
            ['name' => 'قلب', 'e_name' => 'Heart', 'price' => 50, 'sort' => 2,
                'image_type' => 'svg',
                'img' => 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/svg/2764.svg'],
            ['name' => 'تاج', 'e_name' => 'Crown', 'price' => 500, 'sort' => 3,
                'image_type' => 'gif',
                'img' => 'https://upload.wikimedia.org/wikipedia/commons/d/d3/Newtons_cradle_animation_book_2.gif'],
            // NB: the repo's own Rocket.svga is a corrupt/legacy-format file that
            // fails zlib decode, so we use a known-good sample to exercise SVGA.
            // The dashboard renders SVGA via SVGAPlayer-Web (see gift-media column).
            ['name' => 'صاروخ', 'e_name' => 'Rocket', 'price' => 2000, 'sort' => 4,
                'image_type' => 'svga',
                'img' => 'https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/angel.svga'],
        ];

        foreach ($gifts as $g) {
            Gift::updateOrCreate(
                ['e_name' => $g['e_name']],
                [
                    'name'             => $g['name'],
                    'type'             => Gift::TYPE_NORMAL,
                    'gift_category_id' => $normal->id,
                    'price'            => $g['price'],
                    'img'              => $g['img'],
                    'show_img'         => $g['img'],
                    'image_type'       => $g['image_type'],
                    'sort'             => $g['sort'],
                    'enable'           => true,
                ],
            );
        }
    }
}
