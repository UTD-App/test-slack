<?php

namespace App\Facades;

use App\Services\TranslatableContentRegistry;
use App\Support\Translatable\TranslatableSource;
use Illuminate\Support\Facades\Facade;

/**
 * Catalogue of translatable dynamic-content sources. Register a source once in a
 * provider boot() and it appears as a tab on every language's "Content
 * translations" page:
 *
 *   TranslatableContent::register('faqs', [
 *       'label'     => fn () => __('admin.faqs'),
 *       'model'     => \Vendor\Faq\Models\Faq::class,  // uses HasTranslations
 *       'fields'    => ['question' => false, 'answer' => true],
 *       'itemLabel' => fn (Faq $f) => $f->slug,
 *       'editUrl'   => fn (Faq $f) => FaqResource::getUrl('edit', ['record' => $f]),
 *   ]);
 *
 * @method static void register(string $key, array $meta)
 * @method static bool has(string $key)
 * @method static TranslatableSource|null get(string $key)
 * @method static array all()
 * @method static array keys()
 *
 * @see \App\Services\TranslatableContentRegistry
 */
class TranslatableContent extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return TranslatableContentRegistry::class;
    }
}
