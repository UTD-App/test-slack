<?php

namespace Utd\Wallet\Filament\Resources;

use App\Filament\Resources\UserResource;
use App\Filament\Resources\BaseResource;
use App\Filament\Tables\Columns\UserColumn;
use App\Models\User;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\TextInput;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Utd\Wallet\Filament\Resources\WalletTransactionResource\Pages;
use Utd\Wallet\Models\WalletTransaction;

/**
 * Read-only ledger of every wallet movement, across all currencies
 * (admin charges, gifts, games, payouts…).
 */
class WalletTransactionResource extends BaseResource
{
    // Roles & Permissions group (auto-discovered by utd:sync-packages).
    protected static ?string $permissionPrefix = 'wallet_transactions';
    protected static array $permissionAbilities = ['view']; // read-only ledger

    protected static ?string $model = WalletTransaction::class;
    protected static ?string $navigationIcon = 'heroicon-o-banknotes';
    protected static ?int $navigationSort = 2;

    public static function getNavigationLabel(): string { return __('wallet::admin.nav_wallet_transactions'); }
    public static function getModelLabel(): string { return __('wallet::admin.wallet_transaction'); }
    public static function getPluralModelLabel(): string { return __('wallet::admin.nav_wallet_transactions'); }
    public static function getNavigationGroup(): ?string { return __('wallet::admin.nav_wallet_group'); }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with('user.profile'))
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                UserColumn::make('user')
                    ->label(__('wallet::admin.user'))
                    ->profileUrl(fn (WalletTransaction $record) => self::profileUrl($record->user)),
                TextColumn::make('currency')->label(__('wallet::admin.currency'))->badge()->color('gray'),
                TextColumn::make('type')->label(__('wallet::admin.type'))->badge()->color('gray')->searchable(),
                TextColumn::make('amount')
                    ->label(__('wallet::admin.amount'))
                    ->color(fn ($state) => $state >= 0 ? 'success' : 'danger')
                    ->formatStateUsing(fn ($state) => ($state >= 0 ? '+' : '') . number_format((float) $state, 2)),
                TextColumn::make('balance_before')->label(__('wallet::admin.balance_before'))->numeric(2)->toggleable(),
                TextColumn::make('balance_after')->label(__('wallet::admin.balance_after'))->numeric(2),
                TextColumn::make('created_at')->label(__('wallet::admin.date'))->dateTime()->sortable(),
            ])
            ->filters([
                // Currency is split into top tabs (Coins / Diamond) on the list page.

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

                // Direction (credit / debit)
                SelectFilter::make('direction')
                    ->label(__('wallet::admin.direction'))
                    ->options([
                        'credit' => __('wallet::admin.coins_credit'),
                        'debit'  => __('wallet::admin.coins_debit'),
                    ])
                    ->query(fn (Builder $query, array $data) => $query->when(
                        $data['value'] ?? null,
                        fn (Builder $q, $v) => $v === 'credit' ? $q->where('amount', '>=', 0) : $q->where('amount', '<', 0),
                    )),

                // Type
                SelectFilter::make('type')
                    ->label(__('wallet::admin.type'))
                    ->options(fn () => WalletTransaction::query()->distinct()->pluck('type', 'type')->all()),

                // User (name / UID)
                Filter::make('user')
                    ->form([TextInput::make('q')->label(__('wallet::admin.filter_user'))])
                    ->query(fn (Builder $query, array $data) => $query->when($data['q'] ?? null, function (Builder $q, $v) {
                        $ids = User::query()
                            ->where('name', 'like', "%{$v}%")
                            ->orWhere('uuid', 'like', "%{$v}%")
                            ->limit(100)->pluck('id');
                        $q->whereIn('user_id', $ids);
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
            'index' => Pages\ListWalletTransactions::route('/'),
        ];
    }

    public static function canCreate(): bool { return false; }
    public static function canEdit($record): bool { return false; }
    public static function canDelete($record): bool { return false; }
}
