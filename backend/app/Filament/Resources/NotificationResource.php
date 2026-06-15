<?php

namespace App\Filament\Resources;

use App\Filament\Resources\NotificationResource\Pages;
use App\Filament\Tables\Columns\UserColumn;
use App\Models\Notification;
use App\Services\Notifications\NotificationManager;
use App\Services\Notifications\NotificationTypeRegistry;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

/**
 * Read-only admin view of the in-app notification feed, plus an "announcement"
 * composer (header action on the list page) that broadcasts to all users — the
 * modern replacement for the old official_messages flow. Rows store type+params;
 * the body is rendered here in the admin's locale.
 */
class NotificationResource extends BaseResource
{
    protected static ?string $permissionPrefix = 'notifications';
    protected static ?string $model = Notification::class;
    protected static ?string $navigationIcon = 'heroicon-o-bell';
    protected static ?int $navigationSort = 30;

    // Not shown in the sidebar menu (route still works for the announcement
    // composer if linked directly). The in-app feed is surfaced to users via the
    // mobile API / my-data badge, so a dedicated admin menu item isn't needed.
    protected static bool $shouldRegisterNavigation = false;

    public static function getModelLabel(): string
    {
        return __('admin.notifications') !== 'admin.notifications' ? __('admin.notifications') : 'Notification';
    }

    /** This resource shows the user-facing in-app feed; admin/dashboard ones live in the dashboard widget. */
    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->where('notifiable_type', Notification::AUDIENCE_USER);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['notifiable.profile', 'actor.profile']))
            ->columns([
                UserColumn::make('notifiable')
                    ->label(__('admin.user'))
                    ->profileUrl(fn ($record) => $record->notifiable_id
                        ? UserResource::getUrl('view', ['record' => $record->notifiable_id])
                        : null),
                TextColumn::make('type')->label(__('admin.type'))->badge()->sortable()->searchable(),
                TextColumn::make('category')->label(__('admin.category'))->badge()->toggleable(),
                TextColumn::make('body')
                    ->label(__('admin.body'))
                    ->getStateUsing(fn (Notification $record) => static::renderBody($record))
                    ->limit(60)
                    ->wrap(),
                IconColumn::make('read_at')
                    ->label(__('admin.read'))
                    ->boolean()
                    ->getStateUsing(fn (Notification $record) => $record->read_at !== null),
                TextColumn::make('created_at')->label(__('admin.created_at'))->dateTime()->sortable(),
            ])
            ->filters([
                SelectFilter::make('category')
                    ->options(fn () => collect(app(NotificationTypeRegistry::class)->categories())
                        ->mapWithKeys(fn ($c) => [$c => $c])
                        ->all()),
            ])
            ->defaultSort('created_at', 'desc');
    }

    /** Render a row's body in the admin's current locale (rows hold type+params). */
    protected static function renderBody(Notification $record): string
    {
        $type = app(NotificationTypeRegistry::class)->get($record->type);
        if (! $type) {
            return $record->type;
        }

        return app(NotificationManager::class)->render($type, $record->params ?? [], app()->getLocale())['body'];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListNotifications::route('/'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
    }
}
