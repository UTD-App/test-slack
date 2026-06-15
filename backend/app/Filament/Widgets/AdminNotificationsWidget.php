<?php

namespace App\Filament\Widgets;

use App\Models\Notification;
use App\Services\Notifications\NotificationManager;
use App\Services\Notifications\NotificationTypeRegistry;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Database\Eloquent\Builder;

/**
 * Dashboard inbox for admin-addressed notifications (reports, moderation, …)
 * sent via Notifier::toAdmins(). Shared across all admins; "Mark read" acks the
 * row. Bodies render in the admin's locale (rows store type+params).
 */
class AdminNotificationsWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected int|string|array $columnSpan = 'full';

    public static function canView(): bool
    {
        $user = filament()->auth()->user();

        return $user instanceof \App\Models\AdminUser
            && $user->hasPermission('notifications.view');
    }

    public function getTableHeading(): string
    {
        return __('admin.notifications') !== 'admin.notifications' ? __('admin.notifications') : 'Notifications';
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(fn (): Builder => Notification::query()->forAdmins()->latest())
            ->defaultPaginationPageOption(10)
            ->columns([
                IconColumn::make('read_at')
                    ->label('')
                    ->getStateUsing(fn (Notification $r) => $r->read_at === null)
                    ->boolean()
                    ->trueIcon('heroicon-s-bell-alert')
                    ->falseIcon('heroicon-o-check')
                    ->trueColor('warning')
                    ->falseColor('gray'),
                TextColumn::make('type')->label(__('admin.type'))->badge(),
                TextColumn::make('body')
                    ->label(__('admin.body'))
                    ->getStateUsing(fn (Notification $r) => static::renderBody($r))
                    ->wrap(),
                TextColumn::make('created_at')->label(__('admin.created_at'))->since()->sortable(),
            ])
            ->actions([
                Action::make('markRead')
                    ->label(__('admin.mark_read'))
                    ->icon('heroicon-o-check')
                    ->hidden(fn (Notification $r) => $r->read_at !== null)
                    ->action(fn (Notification $r) => $r->update(['read_at' => now()])),
            ]);
    }

    protected static function renderBody(Notification $record): string
    {
        $type = app(NotificationTypeRegistry::class)->get($record->type);
        if (! $type) {
            return $record->type;
        }

        return app(NotificationManager::class)->render($type, $record->params ?? [], app()->getLocale())['body'];
    }
}
