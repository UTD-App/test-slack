<?php

namespace Utd\Gifts\Filament\Resources;

use App\Filament\Resources\BaseResource;
use App\Filament\Resources\UserResource;
use App\Filament\Tables\Columns\UserColumn;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ViewColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Utd\Gifts\Filament\Resources\GiftLogResource\Pages;
use Utd\Gifts\Models\Gift;
use Utd\Gifts\Models\GiftLog;

/**
 * Read-only history of every gift sent (sender → receiver, coins spent, diamonds earned).
 */
class GiftLogResource extends BaseResource
{
    protected static ?string $packageSlug = 'gifts';
    protected static ?string $permissionPrefix = 'gift_logs';
    protected static array $permissionAbilities = ['view']; // read-only history

    protected static ?string $model = GiftLog::class;
    protected static ?string $navigationIcon = 'heroicon-o-clock';
    protected static ?int $navigationSort = 3;

    public static function getNavigationLabel(): string { return __('gifts::admin.nav_gift_logs'); }
    public static function getModelLabel(): string { return __('gifts::admin.gift_log'); }
    public static function getPluralModelLabel(): string { return __('gifts::admin.nav_gift_logs'); }
    public static function getNavigationGroup(): ?string { return __('gifts::admin.nav_gifts_group'); }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['gift', 'sender.profile', 'receiver.profile']))
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                ViewColumn::make('gift_name')->label(__('gifts::admin.gift'))
                    ->view('gifts::filament.columns.gift-log-cell'),
                UserColumn::make('sender')->label(__('gifts::admin.sender'))
                    ->profileUrl(fn (GiftLog $record) => self::userProfileUrl($record->sender)),
                UserColumn::make('receiver')->label(__('gifts::admin.receiver'))
                    ->profileUrl(fn (GiftLog $record) => self::userProfileUrl($record->receiver)),
                TextColumn::make('gift_num')->label(__('gifts::admin.quantity')),
                TextColumn::make('total_price')->label(__('gifts::admin.total'))->numeric(2),
                TextColumn::make('receiver_earned')->label(__('gifts::admin.earned'))->numeric(2),
                TextColumn::make('context_type')->label(__('gifts::admin.context'))->badge()->placeholder('—'),
                TextColumn::make('spend_currency')->label(__('gifts::admin.filter_spend'))->badge()->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('earn_currency')->label(__('gifts::admin.filter_earn'))->badge()->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('created_at')->label(__('gifts::admin.date'))->dateTime()->sortable(),
            ])
            ->filters([
                // Date range
                Filter::make('created_at')
                    ->form([
                        DatePicker::make('from')->label(__('gifts::admin.filter_from')),
                        DatePicker::make('until')->label(__('gifts::admin.filter_until')),
                    ])
                    ->query(fn (Builder $query, array $data) => $query
                        ->when($data['from'] ?? null, fn (Builder $q, $d) => $q->whereDate('created_at', '>=', $d))
                        ->when($data['until'] ?? null, fn (Builder $q, $d) => $q->whereDate('created_at', '<=', $d)))
                    ->indicateUsing(function (array $data): array {
                        $i = [];
                        if ($data['from'] ?? null) { $i[] = __('gifts::admin.filter_from') . ': ' . $data['from']; }
                        if ($data['until'] ?? null) { $i[] = __('gifts::admin.filter_until') . ': ' . $data['until']; }
                        return $i;
                    }),

                // Sender UID
                Filter::make('sender_uid')
                    ->form([TextInput::make('sender_id')->label(__('gifts::admin.filter_sender_uid'))->numeric()])
                    ->query(fn (Builder $query, array $data) => $query
                        ->when($data['sender_id'] ?? null, fn (Builder $q, $v) => $q->where('sender_id', $v)))
                    ->indicateUsing(fn (array $data) => ($data['sender_id'] ?? null)
                        ? __('gifts::admin.filter_sender_uid') . ': ' . $data['sender_id'] : null),

                // Receiver UID
                Filter::make('receiver_uid')
                    ->form([TextInput::make('receiver_id')->label(__('gifts::admin.filter_receiver_uid'))->numeric()])
                    ->query(fn (Builder $query, array $data) => $query
                        ->when($data['receiver_id'] ?? null, fn (Builder $q, $v) => $q->where('receiver_id', $v)))
                    ->indicateUsing(fn (array $data) => ($data['receiver_id'] ?? null)
                        ? __('gifts::admin.filter_receiver_uid') . ': ' . $data['receiver_id'] : null),

                // Any user (sender OR receiver)
                Filter::make('user_uid')
                    ->form([TextInput::make('user_id')->label(__('gifts::admin.filter_user_uid'))->numeric()])
                    ->query(fn (Builder $query, array $data) => $query
                        ->when($data['user_id'] ?? null, fn (Builder $q, $v) => $q
                            ->where(fn (Builder $w) => $w->where('sender_id', $v)->orWhere('receiver_id', $v))))
                    ->indicateUsing(fn (array $data) => ($data['user_id'] ?? null)
                        ? __('gifts::admin.filter_user_uid') . ': ' . $data['user_id'] : null),

                // Gift
                SelectFilter::make('gift_id')
                    ->label(__('gifts::admin.filter_gift'))
                    ->options(fn () => Gift::query()->orderBy('sort')->pluck('name', 'id')->all())
                    ->searchable(),

                // Context type
                SelectFilter::make('context_type')
                    ->label(__('gifts::admin.filter_context_type'))
                    ->options([
                        'moment' => __('gifts::admin.context_moment'),
                        'real'   => __('gifts::admin.context_real'),
                        'room'   => __('gifts::admin.context_room'),
                    ]),

                // Spend currency
                SelectFilter::make('spend_currency')
                    ->label(__('gifts::admin.filter_spend'))
                    ->options(fn () => GiftLog::query()->distinct()->pluck('spend_currency', 'spend_currency')->all()),

                // Earn currency
                SelectFilter::make('earn_currency')
                    ->label(__('gifts::admin.filter_earn'))
                    ->options(fn () => GiftLog::query()->distinct()->pluck('earn_currency', 'earn_currency')->all()),
            ])
            ->filtersFormColumns(3)
            ->defaultSort('created_at', 'desc');
    }

    /**
     * Link a user cell to its admin profile page. Returns null (no link) when the
     * user is missing or the base UserResource isn't part of this assembly.
     */
    protected static function userProfileUrl(?object $user): ?string
    {
        if (! $user || ! class_exists(UserResource::class)) {
            return null;
        }

        return UserResource::getUrl('view', ['record' => $user->getKey()]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListGiftLogs::route('/'),
        ];
    }

    public static function canCreate(): bool { return false; }
    public static function canEdit($record): bool { return false; }
    public static function canDelete($record): bool { return false; }
}
