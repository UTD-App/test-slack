<?php

namespace Utd\Wallet\Filament\Resources;

use App\Filament\Resources\BaseResource;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Form;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Utd\Wallet\Filament\Resources\CoinResource\Pages;
use Utd\Wallet\Models\Coin;
use Utd\Wallet\Models\PaymentCoin;

/**
 * Purchasable coin PACKAGES (the recharge catalogue served by the app's
 * GET /api/coins). Pay `usd` → receive `coin` (+ first-charge / promo bonus),
 * grouped under a PaymentCoin. Previously only manageable via raw DB/seeder —
 * now full CRUD from the dashboard.
 */
class CoinResource extends BaseResource
{
    protected static ?string $packageSlug = 'wallet';
    protected static ?string $permissionPrefix = 'coins';
    protected static array $permissionAbilities = ['view', 'create', 'update', 'delete'];

    protected static ?string $model = Coin::class;
    protected static ?string $navigationIcon = 'heroicon-o-currency-dollar';
    protected static ?int $navigationSort = 3;

    public static function getNavigationLabel(): string { return __('wallet::admin.nav_coins'); }
    public static function getModelLabel(): string { return __('wallet::admin.coin'); }
    public static function getPluralModelLabel(): string { return __('wallet::admin.nav_coins'); }
    public static function getNavigationGroup(): ?string { return __('wallet::admin.nav_wallet_group'); }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Select::make('payment_gateway_id')
                ->label(__('wallet::admin.payment_group'))
                ->options(fn () => PaymentCoin::query()->orderBy('title')->pluck('title', 'id')->all())
                ->searchable(),
            TextInput::make('usd')
                ->label(__('wallet::admin.usd'))
                ->numeric()
                ->minValue(0)
                ->required(),
            TextInput::make('coin')
                ->label(__('wallet::admin.coin_amount'))
                ->numeric()
                ->minValue(0)
                ->required(),
            TextInput::make('first_charge_coin')
                ->label(__('wallet::admin.first_charge_coin'))
                ->numeric()
                ->minValue(0)
                ->default(0),
            TextInput::make('extra_value')
                ->label(__('wallet::admin.extra_value'))
                ->numeric()
                ->minValue(0)
                ->default(0),
            TextInput::make('extra_value_end_in')
                ->label(__('wallet::admin.extra_value_end_in'))
                ->numeric()
                ->helperText(__('wallet::admin.days_hint')),
            TextInput::make('discount_code')
                ->label(__('wallet::admin.discount_code'))
                ->maxLength(255),
            TextInput::make('discount_code_expire_in')
                ->label(__('wallet::admin.discount_code_expire_in'))
                ->numeric()
                ->helperText(__('wallet::admin.days_hint')),
            TextInput::make('sort')
                ->label(__('wallet::admin.sort'))
                ->numeric()
                ->default(0),
            Toggle::make('status')
                ->label(__('wallet::admin.active'))
                ->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with('paymentCoin'))
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                TextColumn::make('paymentCoin.title')->label(__('wallet::admin.payment_group'))->placeholder('—'),
                TextColumn::make('usd')->label(__('wallet::admin.usd'))->money('USD')->sortable(),
                TextColumn::make('coin')->label(__('wallet::admin.coin_amount'))->numeric()->sortable(),
                TextColumn::make('first_charge_coin')->label(__('wallet::admin.first_charge_coin'))->numeric()->toggleable(),
                TextColumn::make('extra_value')->label(__('wallet::admin.extra_value'))->numeric()->toggleable(),
                TextColumn::make('sort')->label(__('wallet::admin.sort'))->sortable()->toggleable(),
                IconColumn::make('status')->label(__('wallet::admin.active'))->boolean(),
            ])
            ->filters([
                SelectFilter::make('payment_gateway_id')
                    ->label(__('wallet::admin.payment_group'))
                    ->options(fn () => PaymentCoin::query()->orderBy('title')->pluck('title', 'id')->all()),
            ])
            ->defaultSort('sort', 'asc');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListCoins::route('/'),
            'create' => Pages\CreateCoin::route('/create'),
            'edit'   => Pages\EditCoin::route('/{record}/edit'),
        ];
    }
}
