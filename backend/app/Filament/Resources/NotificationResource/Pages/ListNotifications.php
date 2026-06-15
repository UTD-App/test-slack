<?php

namespace App\Filament\Resources\NotificationResource\Pages;

use App\Facades\Notifier;
use App\Filament\Resources\NotificationResource;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification as FilamentNotification;
use Filament\Resources\Pages\ListRecords;

/**
 * Notification feed list + the "Send announcement" composer. The composer
 * broadcasts a `system.announcement` to every user with per-locale title/body;
 * each recipient's feed renders it in their own language (replaces the old
 * official_messages broadcast).
 */
class ListNotifications extends ListRecords
{
    protected static string $resource = NotificationResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('announce')
                ->label(__('admin.send_announcement'))
                ->icon('heroicon-o-megaphone')
                ->visible(fn (): bool => filament()->auth()->user()?->can('notifications.broadcast') ?? false)
                ->form([
                    TextInput::make('title_en')->label(__('admin.page_title_en'))->maxLength(150),
                    TextInput::make('title_ar')->label(__('admin.page_title_ar'))->maxLength(150),
                    Textarea::make('body_en')->label(__('admin.page_body_en'))->required()->rows(4),
                    Textarea::make('body_ar')->label(__('admin.page_body_ar'))->required()->rows(4),
                ])
                ->action(function (array $data): void {
                    Notifier::broadcast('system.announcement', [
                        'title' => ['en' => $data['title_en'] ?? '', 'ar' => $data['title_ar'] ?? ''],
                        'body'  => ['en' => $data['body_en'] ?? '', 'ar' => $data['body_ar'] ?? ''],
                    ]);

                    FilamentNotification::make()
                        ->title(__('admin.announcement_queued'))
                        ->success()
                        ->send();
                }),
        ];
    }
}
