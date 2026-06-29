<?php

namespace Utd\Wallet\Filament\Resources;

use App\Filament\Resources\BaseResource;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Form;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Utd\Wallet\Filament\Resources\PaymentCoinResource\Pages;
use Utd\Wallet\Models\PaymentCoin;

/**
 * Coin payment GROUPS (card / wallet / gateway) within a package_type. Each group
 * holds the purchasable Coin packages shown on the recharge screen. Previously
 * only manageable via raw DB/seeder — now full CRUD from the dashboard.
 */
class PaymentCoinResource extends BaseResource
{
    protected static ?string $packageSlug = 'wallet';
    protected static ?string $permissionPrefix = 'payment_coins';
    protected static array $permissionAbilities = ['view', 'create', 'update', 'delete'];

    protected static ?string $model = PaymentCoin::class;
    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';
    protected static ?int $navigationSort = 2;

    public static function getNavigationLabel(): string { return __('wallet::admin.nav_payment_coins'); }
    public static function getModelLabel(): string { return __('wallet::admin.payment_coin'); }
    public static function getPluralModelLabel(): string { return __('wallet::admin.nav_payment_coins'); }
    public static function getNavigationGroup(): ?string { return __('wallet::admin.nav_wallet_group'); }

    public static function form(Form $form): Form
    {
        return $form->schema([
            TextInput::make('title')
                ->label(__('wallet::admin.title'))
                ->required()
                ->maxLength(255),
            Select::make('package_type')
                ->label(__('wallet::admin.package_type'))
                ->options([
                    'user'            => __('wallet::admin.package_type_user'),
                    'shipping_agency' => __('wallet::admin.package_type_agency'),
                ])
                ->default('user')
                ->required(),
            TextInput::make('type')
                ->label(__('wallet::admin.type'))
                ->maxLength(255),
            Toggle::make('status')
                ->label(__('wallet::admin.active'))
                ->default(true),
            Textarea::make('description')
                ->label(__('wallet::admin.description'))
                ->rows(3)
                ->columnSpanFull(),
            FileUpload::make('photo')
                ->label(__('wallet::admin.photo'))
                ->image()
                ->directory('payment_coins')
                ->columnSpanFull(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                TextColumn::make('title')->label(__('wallet::admin.title'))->searchable(),
                TextColumn::make('package_type')->label(__('wallet::admin.package_type'))->badge()->color('gray'),
                TextColumn::make('type')->label(__('wallet::admin.type'))->placeholder('—'),
                TextColumn::make('coins_count')->label(__('wallet::admin.coins_count'))->counts('coins'),
                IconColumn::make('status')->label(__('wallet::admin.active'))->boolean(),
                TextColumn::make('created_at')->label(__('wallet::admin.date'))->dateTime()->sortable()->toggleable(),
            ])
            ->filters([
                SelectFilter::make('package_type')
                    ->label(__('wallet::admin.package_type'))
                    ->options([
                        'user'            => __('wallet::admin.package_type_user'),
                        'shipping_agency' => __('wallet::admin.package_type_agency'),
                    ]),
            ])
            ->defaultSort('id', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListPaymentCoins::route('/'),
            'create' => Pages\CreatePaymentCoin::route('/create'),
            'edit'   => Pages\EditPaymentCoin::route('/{record}/edit'),
        ];
    }
}
