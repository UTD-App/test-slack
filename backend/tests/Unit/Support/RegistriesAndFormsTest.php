<?php

namespace Tests\Unit\Support;

use App\Support\Translatable\DefaultLocaleForm;
use App\Support\UserProfileInfolistRegistry;
use App\Support\UserProfileTabRegistry;
use Tests\TestCase;

/**
 * Pure registry + form-glue logic (no DB, no Filament boot needed).
 */
class RegistriesAndFormsTest extends TestCase
{
    // ---- UserProfileTabRegistry -------------------------------------------

    public function test_tab_registry_orders_by_order_then_registration(): void
    {
        $reg = new UserProfileTabRegistry();
        $reg->register('b', 'B::class', 10);
        $reg->register('a', 'A::class', 5);
        $reg->register('c', 'C::class', 5); // tie with a → registration order kept

        $this->assertSame(['A::class', 'C::class', 'B::class'], $reg->all());
    }

    public function test_tab_registry_is_idempotent_per_id(): void
    {
        $reg = new UserProfileTabRegistry();
        $reg->register('x', 'First::class');
        $reg->register('x', 'Second::class'); // same id overwrites

        $this->assertSame(['Second::class'], $reg->all());
    }

    public function test_tab_registry_empty_by_default(): void
    {
        $this->assertSame([], (new UserProfileTabRegistry())->all());
    }

    // ---- UserProfileInfolistRegistry --------------------------------------

    public function test_infolist_registry_has_and_resolve(): void
    {
        $reg = new UserProfileInfolistRegistry();
        $this->assertFalse($reg->has());
        $this->assertNull($reg->resolve());

        $builder = fn ($i) => $i;
        $reg->register($builder);

        $this->assertTrue($reg->has());
        $this->assertSame($builder, $reg->resolve());
    }

    public function test_infolist_registry_last_registration_wins(): void
    {
        $reg = new UserProfileInfolistRegistry();
        $first = fn ($i) => $i;
        $second = fn ($i) => $i;
        $reg->register($first);
        $reg->register($second);

        $this->assertSame($second, $reg->resolve());
    }

    // ---- DefaultLocaleForm -------------------------------------------------

    public function test_to_form_extracts_default_locale_value(): void
    {
        $data = ['title' => ['en' => 'Hello', 'fr' => 'Bonjour'], 'other' => 'x'];

        $out = DefaultLocaleForm::toForm($data, ['title'], 'en');

        $this->assertSame('Hello', $out['title_default']);
        $this->assertArrayNotHasKey('title', $out);   // original map removed
        $this->assertSame('x', $out['other']);        // untouched
    }

    public function test_to_form_missing_map_yields_empty_string(): void
    {
        $out = DefaultLocaleForm::toForm(['title' => null], ['title'], 'en');
        $this->assertSame('', $out['title_default']);
    }

    public function test_to_model_merges_into_existing_map_preserving_other_locales(): void
    {
        $data = ['title_default' => 'Updated EN'];
        $existing = ['title' => ['en' => 'Old EN', 'fr' => 'Bonjour']];

        $out = DefaultLocaleForm::toModel($data, ['title'], 'en', $existing);

        // Other locale preserved, default overwritten.
        $this->assertSame(['en' => 'Updated EN', 'fr' => 'Bonjour'], $out['title']);
        $this->assertArrayNotHasKey('title_default', $out);
    }

    public function test_to_model_creates_map_when_no_existing(): void
    {
        $out = DefaultLocaleForm::toModel(['body_default' => 'Hi'], ['body'], 'en');
        $this->assertSame(['en' => 'Hi'], $out['body']);
    }

    public function test_to_form_to_model_round_trip(): void
    {
        $model = ['title' => ['en' => 'Hello', 'fr' => 'Bonjour']];
        $form = DefaultLocaleForm::toForm($model, ['title'], 'en');
        $back = DefaultLocaleForm::toModel($form, ['title'], 'en', $model);

        $this->assertSame($model['title'], $back['title']);
    }
}
