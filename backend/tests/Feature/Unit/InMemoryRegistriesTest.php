<?php

namespace Tests\Feature\Unit;

use App\Models\User;
use App\Services\Mail\EmailTemplateRegistry;
use App\Services\TranslatableContentRegistry;
use App\Services\TranslationGroupRegistry;
use App\Support\Mail\EmailTemplateType;
use App\Support\Translatable\TranslatableSource;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The pure in-memory catalogue registries (no DB): EmailTemplateRegistry,
 * TranslatableContentRegistry, TranslationGroupRegistry. register/has/get/all/keys,
 * override semantics, and metadata mapping.
 */
class InMemoryRegistriesTest extends TestCase
{
    use RefreshDatabase;

    // ── EmailTemplateRegistry ─────────────────────────────────────────────────

    public function test_email_register_maps_meta_and_resolves_closures(): void
    {
        $registry = new EmailTemplateRegistry();
        $registry->register('password_reset_otp', [
            'label'          => fn () => 'Password Reset',
            'description'    => fn () => 'Sends an OTP',
            'placeholders'   => ['otp' => 'The code'],
            'default_subject'=> fn (string $locale) => "subject-$locale",
            'default_body'   => fn (string $locale) => "<p>body-$locale</p>",
        ]);

        $type = $registry->get('password_reset_otp');

        $this->assertInstanceOf(EmailTemplateType::class, $type);
        $this->assertSame('Password Reset', $type->label());
        $this->assertSame('Sends an OTP', $type->description());
        $this->assertSame(['otp' => 'The code'], $type->placeholders);
        $this->assertSame('subject-en', $type->defaultSubject('en'));
        $this->assertSame('<p>body-ar</p>', $type->defaultBody('ar'));
    }

    public function test_email_defaults_when_meta_omitted(): void
    {
        $registry = new EmailTemplateRegistry();
        $registry->register('bare', []);

        $type = $registry->get('bare');
        $this->assertSame('bare', $type->label()); // label defaults to key
        $this->assertSame('', $type->description());
        $this->assertSame([], $type->placeholders);
        $this->assertSame('', $type->defaultSubject('en'));
    }

    public function test_email_has_get_keys_and_unknown(): void
    {
        $registry = new EmailTemplateRegistry();
        $registry->register('a', []);
        $registry->register('b', []);

        $this->assertTrue($registry->has('a'));
        $this->assertFalse($registry->has('z'));
        $this->assertNull($registry->get('z'));
        $this->assertSame(['a', 'b'], $registry->keys());
        $this->assertCount(2, $registry->all());
    }

    public function test_email_register_overrides(): void
    {
        $registry = new EmailTemplateRegistry();
        $registry->register('t', ['label' => fn () => 'first']);
        $registry->register('t', ['label' => fn () => 'second']);

        $this->assertSame('second', $registry->get('t')->label());
        $this->assertCount(1, $registry->all());
    }

    // ── TranslatableContentRegistry ───────────────────────────────────────────

    public function test_translatable_register_and_lookup(): void
    {
        $registry = new TranslatableContentRegistry();
        $registry->register('pages', [
            'label'  => fn () => 'Pages',
            'model'  => User::class, // any model class satisfies the require
            'fields' => ['title' => false, 'body' => true],
        ]);

        $source = $registry->get('pages');
        $this->assertInstanceOf(TranslatableSource::class, $source);
        $this->assertSame('Pages', $source->label());
        $this->assertSame(['title', 'body'], $source->fieldNames());
        $this->assertTrue($source->isHtml('body'));
        $this->assertFalse($source->isHtml('title'));
        $this->assertTrue($registry->has('pages'));
        $this->assertSame(['pages'], $registry->keys());
    }

    public function test_translatable_register_requires_model(): void
    {
        $registry = new TranslatableContentRegistry();

        $this->expectException(\InvalidArgumentException::class);
        $registry->register('bad', ['fields' => []]); // no model
    }

    public function test_translatable_unknown_lookup(): void
    {
        $registry = new TranslatableContentRegistry();

        $this->assertFalse($registry->has('nope'));
        $this->assertNull($registry->get('nope'));
        $this->assertSame([], $registry->keys());
    }

    // ── TranslationGroupRegistry ──────────────────────────────────────────────

    public function test_translation_group_register_trims_trailing_slash(): void
    {
        $registry = new TranslationGroupRegistry();
        $registry->register('gifts', '/path/to/lang/');

        $this->assertSame(['gifts' => '/path/to/lang'], $registry->all());
    }

    public function test_translation_group_ignores_empty_group_or_dir(): void
    {
        $registry = new TranslationGroupRegistry();
        $registry->register('', '/path');
        $registry->register('gifts', '');

        $this->assertSame([], $registry->all());
    }

    public function test_translation_group_keeps_registration_order_and_overrides(): void
    {
        $registry = new TranslationGroupRegistry();
        $registry->register('gifts', '/a');
        $registry->register('moment', '/b');
        $registry->register('gifts', '/c'); // override, position kept

        $this->assertSame(['gifts' => '/c', 'moment' => '/b'], $registry->all());
    }
}
