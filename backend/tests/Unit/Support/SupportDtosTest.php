<?php

namespace Tests\Unit\Support;

use App\Support\Mail\EmailTemplateType;
use App\Support\Media\MediaResult;
use App\Support\Notifications\NotificationMessage;
use App\Support\Notifications\NotificationType;
use App\Support\Wallet\WalletResult;
use Tests\TestCase;

/**
 * Pure immutable value objects / DTOs: constructors, factories, toArray() shape.
 */
class SupportDtosTest extends TestCase
{
    public function test_media_result_to_array(): void
    {
        $r = new MediaResult('uploads/a.jpg', 'https://cdn/a.jpg', 'gcs', 1234, 'image/jpeg');

        $this->assertSame([
            'path' => 'uploads/a.jpg',
            'url'  => 'https://cdn/a.jpg',
            'disk' => 'gcs',
            'size' => 1234,
            'mime' => 'image/jpeg',
        ], $r->toArray());
    }

    public function test_media_result_optional_fields_default_null(): void
    {
        $r = new MediaResult('p', 'u');
        $this->assertNull($r->disk);
        $this->assertNull($r->size);
        $this->assertNull($r->mime);
    }

    public function test_wallet_result_to_array(): void
    {
        $r = new WalletResult(true, 'COINS', 10.0, 90.0, 'gift', 'tx_1', ['k' => 'v']);

        $this->assertSame([
            'success'        => true,
            'currency'       => 'COINS',
            'amount'         => 10.0,
            'balance'        => 90.0,
            'reason'         => 'gift',
            'transaction_id' => 'tx_1',
            'meta'           => ['k' => 'v'],
        ], $r->toArray());
    }

    public function test_notification_message_make(): void
    {
        $m = NotificationMessage::make('Title', 'Body', ['x' => 1], 'https://img');

        $this->assertSame('Title', $m->title);
        $this->assertSame('Body', $m->body);
        $this->assertSame(['x' => 1], $m->data);
        $this->assertSame('https://img', $m->imageUrl);
    }

    public function test_notification_message_defaults(): void
    {
        $m = NotificationMessage::make('T', 'B');
        $this->assertSame([], $m->data);
        $this->assertNull($m->imageUrl);
    }

    public function test_notification_type_from_array_defaults(): void
    {
        $t = NotificationType::fromArray('social.follow', []);

        $this->assertSame('social.follow', $t->key);
        $this->assertSame('social.follow', $t->bodyKey);   // defaults to key
        $this->assertNull($t->titleKey);
        $this->assertSame('system', $t->category);          // default category
        $this->assertSame(['database', 'push'], $t->channels);
        $this->assertNull($t->icon);
        $this->assertNull($t->route);
    }

    public function test_notification_type_from_array_overrides(): void
    {
        $t = NotificationType::fromArray('social.follow', [
            'body_key'  => 'social::notifications.follow',
            'title_key' => 'social::notifications.follow_title',
            'category'  => 'social',
            'channels'  => ['database'],
            'icon'      => 'user-plus',
            'route'     => '/profile/:user_id',
        ]);

        $this->assertSame('social::notifications.follow', $t->bodyKey);
        $this->assertSame('social::notifications.follow_title', $t->titleKey);
        $this->assertSame('social', $t->category);
        $this->assertSame(['database'], $t->channels);
        $this->assertSame('user-plus', $t->icon);
        $this->assertSame('/profile/:user_id', $t->route);
    }

    public function test_email_template_type_from_array_defaults_and_closures(): void
    {
        $t = EmailTemplateType::fromArray('password_reset_otp', []);

        $this->assertSame('password_reset_otp', $t->key);
        // Default label closure returns the key; description/subject/body empty.
        $this->assertSame('password_reset_otp', $t->label());
        $this->assertSame('', $t->description());
        $this->assertSame('', $t->defaultSubject('en'));
        $this->assertSame('', $t->defaultBody('ar'));
        $this->assertSame([], $t->placeholders);
    }

    public function test_email_template_type_invokes_locale_aware_closures(): void
    {
        $t = EmailTemplateType::fromArray('welcome', [
            'label'          => fn () => 'Welcome',
            'description'    => fn () => 'Sent on signup',
            'placeholders'   => ['name' => 'User name'],
            'default_subject'=> fn (string $locale) => "subject-$locale",
            'default_body'   => fn (string $locale) => "<p>body-$locale</p>",
        ]);

        $this->assertSame('Welcome', $t->label());
        $this->assertSame('Sent on signup', $t->description());
        $this->assertSame(['name' => 'User name'], $t->placeholders);
        $this->assertSame('subject-en', $t->defaultSubject('en'));
        $this->assertSame('<p>body-ar</p>', $t->defaultBody('ar'));
    }
}
