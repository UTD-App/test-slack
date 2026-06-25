<?php

namespace Utd\Wallet\Filament\Resources;

use App\Filament\Resources\BaseResource;
use App\Filament\Resources\UserResource;
use App\Filament\Tables\Columns\UserColumn;
use App\Models\User;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Utd\Wallet\Filament\Resources\ChargeResource\Pages;
use Utd\Wallet\Models\Charge;

/**
 * Manual charges (admin → user). List = charge history; Create = the charge form.
 * The actual balance move + audit happen in Utd\Wallet\Services\ChargeService.
 */
class ChargeResource extends BaseResource
{
    // Roles & Permissions group (auto-discovered by utd:sync-packages).
    protected static ?string $permissionPrefix = 'charges';
    protected static array $permissionAbilities = ['view', 'create'];

    protected static ?string $model = Charge::class;
    protected static ?string $navigationIcon = 'heroicon-o-credit-card';
    protected static ?int $navigationSort = 1;

    public static function getNavigationLabel(): string { return __('wallet::admin.nav_charges'); }
    public static function getModelLabel(): string { return __('wallet::admin.charge'); }
    public static function getPluralModelLabel(): string { return __('wallet::admin.nav_charges'); }
    public static function getNavigationGroup(): ?string { return __('wallet::admin.nav_wallet_group'); }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Select::make('user_id')
                ->label(__('wallet::admin.target_user'))
                ->searchable()
                ->required()
                ->getSearchResultsUsing(fn (string $search) => User::query()
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('uuid', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->limit(20)
                    ->pluck('name', 'id'))
                ->getOptionLabelUsing(fn ($value) => User::find($value)?->name),
            Select::make('currency')
                ->label(__('wallet::admin.currency'))
                ->options(fn () => collect(config('wallet.currencies', ['coins']))->mapWithKeys(fn ($c) => [$c => $c])->all())
                ->default(config('wallet.default_currency', 'coins'))
                ->required(),
            Select::make('direction')
                ->label(__('wallet::admin.direction'))
                ->options([
                    'charge' => __('wallet::admin.coins_credit'),
                    'deduct' => __('wallet::admin.coins_debit'),
                ])
                ->default('charge')
                ->required(),
            TextInput::make('amount')
                ->label(__('wallet::admin.amount'))
                ->numeric()
                ->minValue(0.01)
                ->required(),
            TextInput::make('reason')
                ->label(__('wallet::admin.reason'))
                ->maxLength(255),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with(['target', 'charger']))
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                UserColumn::make('target')
                    ->label(__('wallet::admin.target_user'))
                    ->profileUrl(fn (Charge $record) => self::profileUrl($record->target)),
                TextColumn::make('currency')->label(__('wallet::admin.currency'))->badge()->color('gray'),
                TextColumn::make('amount')
                    ->label(__('wallet::admin.amount'))
                    ->color(fn ($state) => $state >= 0 ? 'success' : 'danger')
                    ->formatStateUsing(fn ($state) => ($state >= 0 ? '+' : '') . number_format((float) $state, 2)),
                TextColumn::make('balance_before')->label(__('wallet::admin.balance_before'))->numeric(2)->toggleable(),
                TextColumn::make('balance_after')->label(__('wallet::admin.balance_after'))->numeric(2),
                TextColumn::make('reason')->label(__('wallet::admin.reason'))->limit(30)->placeholder('—'),
                TextColumn::make('charger_id')
                    ->label(__('wallet::admin.charger'))
                    ->formatStateUsing(fn (Charge $record) => $record->charger?->name ?? __('wallet::admin.system')),
                TextColumn::make('created_at')->label(__('wallet::admin.date'))->dateTime()->sortable(),
            ])
            ->filters([
                // Date range
                Filter::make('created_at')
                    ->form([
                        DatePicker::make('from')->label(__('wallet::admin.filter_from')),
                        DatePicker::make('until')->label(__('wallet::admin.filter_until')),
                    ])
                    ->query(fn (Builder $query, array $data) => $query
                        ->when($data['from'] ?? null, fn (Builder $q, $v) => $q->whereDate('created_at', '>=', $v))
                        ->when($data['until'] ?? null, fn (Builder $q, $v) => $q->whereDate('created_at', '<=', $v)))
                    ->indicateUsing(function (array $data): array {
                        $i = [];
                        if ($data['from'] ?? null) { $i[] = __('wallet::admin.filter_from') . ': ' . $data['from']; }
                        if ($data['until'] ?? null) { $i[] = __('wallet::admin.filter_until') . ': ' . $data['until']; }
                        return $i;
                    }),

                // Direction (charge / deduct)
                SelectFilter::make('direction')
                    ->label(__('wallet::admin.direction'))
                    ->options([
                        'charge' => __('wallet::admin.coins_credit'),
                        'deduct' => __('wallet::admin.coins_debit'),
                    ])
                    ->query(fn (Builder $query, array $data) => $query->when(
                        $data['value'] ?? null,
                        fn (Builder $q, $v) => $v === 'charge' ? $q->where('amount', '>=', 0) : $q->where('amount', '<', 0),
                    )),

                // Currency
                SelectFilter::make('currency')
                    ->label(__('wallet::admin.currency'))
                    ->options(fn () => collect(config('wallet.currencies', ['coins']))->mapWithKeys(fn ($c) => [$c => $c])->all()),

                // Target user (name / UID)
                Filter::make('user')
                    ->form([TextInput::make('q')->label(__('wallet::admin.filter_user'))])
                    ->query(fn (Builder $query, array $data) => $query->when($data['q'] ?? null, function (Builder $q, $v) {
                        $ids = User::query()
                            ->where('name', 'like', "%{$v}%")
                            ->orWhere('uuid', 'like', "%{$v}%")
                            ->limit(100)->pluck('id');
                        $q->where('target_type', User::class)->whereIn('target_id', $ids);
                    }))
                    ->indicateUsing(fn (array $data) => ($data['q'] ?? null)
                        ? __('wallet::admin.filter_user') . ': ' . $data['q'] : null),
            ])
            ->filtersFormColumns(2)
            ->defaultSort('created_at', 'desc');
    }

    /** Link a user cell to its admin profile page (real users only). */
    protected static function profileUrl(?object $user): ?string
    {
        if (! $user instanceof User || ! class_exists(UserResource::class)) {
            return null;
        }

        return UserResource::getUrl('view', ['record' => $user->getKey()]);
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListCharges::route('/'),
            'create' => Pages\CreateCharge::route('/create'),
        ];
    }

    public static function canEdit($record): bool { return false; }
    public static function canDelete($record): bool { return false; }
}
