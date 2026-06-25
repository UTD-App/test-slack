<?php

namespace Utd\Gifts\Filament\Resources;

use App\Filament\Resources\BaseResource;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Form;
use Filament\Tables\Actions\BulkActionGroup;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\DeleteBulkAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ViewColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Utd\Gifts\Filament\Resources\GiftResource\Pages;
use Utd\Gifts\Models\Gift;

class GiftResource extends BaseResource
{
    protected static ?string $packageSlug = 'gifts';
    // Roles & Permissions group (auto-discovered by utd:sync-packages).
    protected static ?string $permissionPrefix = 'gifts';

    protected static ?string $model = Gift::class;
    protected static ?string $navigationIcon = 'heroicon-o-gift';
    protected static ?int $navigationSort = 1;

    public static function getNavigationLabel(): string { return __('gifts::admin.nav_gifts'); }
    public static function getModelLabel(): string { return __('gifts::admin.gift'); }
    public static function getPluralModelLabel(): string { return __('gifts::admin.nav_gifts'); }
    public static function getNavigationGroup(): ?string { return __('gifts::admin.nav_gifts_group'); }

    public static function form(Form $form): Form
    {
        return $form->schema([
            TextInput::make('name')->label(__('gifts::admin.name'))->required()->maxLength(100),
            TextInput::make('e_name')->label(__('gifts::admin.e_name'))->maxLength(100),
            Select::make('type')
                ->label(__('gifts::admin.type'))
                ->options([
                    Gift::TYPE_NORMAL => __('gifts::admin.type_normal'),
                    Gift::TYPE_LUCKY  => __('gifts::admin.type_lucky'),
                ])
                ->default(Gift::TYPE_NORMAL)
                ->required(),
            TextInput::make('price')->label(__('gifts::admin.price'))->numeric()->minValue(0)->default(0)->required(),
            TextInput::make('vip_level')->label(__('gifts::admin.vip_level'))->numeric()->minValue(0)->default(0),
            FileUpload::make('img')->label(__('gifts::admin.img'))
                ->image()
                ->disk('public')
                ->directory('gifts')
                ->visibility('public')
                ->imageEditor()
                ->maxSize(2048)
                ->helperText(__('gifts::admin.img_hint')),
            FileUpload::make('show_img')->label(__('gifts::admin.show_img'))
                ->disk('public')
                ->directory('gifts/animations')
                ->visibility('public')
                ->required()
                ->acceptedFileTypes(['image/png', 'image/jpeg', 'image/gif', 'video/mp4', 'image/svg+xml', 'application/json', 'application/octet-stream'])
                ->maxSize(8192)
                ->helperText(__('gifts::admin.show_img_hint')),
            FileUpload::make('show_img2')->label(__('gifts::admin.show_img2'))
                ->disk('public')
                ->directory('gifts/animations')
                ->visibility('public')
                ->acceptedFileTypes(['image/png', 'image/jpeg', 'image/gif', 'video/mp4', 'image/svg+xml', 'application/json', 'application/octet-stream'])
                ->maxSize(8192)
                ->helperText(__('gifts::admin.show_img2_hint')),
            Select::make('image_type')
                ->label(__('gifts::admin.image_type'))
                ->options([
                    'svga'  => 'SVGA',
                    'alpha' => __('gifts::admin.image_type_alpha'),
                    'mp4'   => 'MP4',
                    'vap'   => 'VAP',
                    'png'   => __('gifts::admin.image_type_png'),
                ])
                ->required(),
            TextInput::make('sort')->label(__('gifts::admin.sort'))->numeric()->default(0),
            Toggle::make('music_gift')->label(__('gifts::admin.music_gift')),
            Toggle::make('international_gift')->label(__('gifts::admin.international_gift')),
            Toggle::make('is_play')->label(__('gifts::admin.is_play')),
            Toggle::make('enable')->label(__('gifts::admin.enable'))->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                ViewColumn::make('img')->label('')->view('gifts::filament.columns.gift-list-media'),
                TextColumn::make('id')->label('ID')->sortable(),
                TextColumn::make('name')->label(__('gifts::admin.name'))->searchable(),
                TextColumn::make('type')->label(__('gifts::admin.type'))->badge()
                    ->formatStateUsing(fn ($state) => (int) $state === Gift::TYPE_LUCKY ? __('gifts::admin.type_lucky') : __('gifts::admin.type_normal')),
                TextColumn::make('price')->label(__('gifts::admin.price'))->numeric()->sortable(),
                TextColumn::make('vip_level')->label(__('gifts::admin.vip_level'))->toggleable(),
                TextColumn::make('use_count')->label(__('gifts::admin.use_count'))->numeric()->sortable()->toggleable(),
                IconColumn::make('enable')->label(__('gifts::admin.enable'))->boolean(),
                TextColumn::make('sort')->label(__('gifts::admin.sort'))->sortable(),
            ])
            ->filters([
                SelectFilter::make('type')
                    ->label(__('gifts::admin.type'))
                    ->options([
                        Gift::TYPE_NORMAL => __('gifts::admin.type_normal'),
                        Gift::TYPE_LUCKY  => __('gifts::admin.type_lucky'),
                    ]),
                TernaryFilter::make('enable')->label(__('gifts::admin.enable')),
            ])
            ->actionsColumnLabel(__('gifts::admin.actions'))
            ->actions([
                EditAction::make()->iconButton(),
                DeleteAction::make()->iconButton(),
            ])
            ->bulkActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ])
            // Drag-and-drop ordering — writes to `sort`, which the frontend
            // gifts endpoint reads (ordered by sort).
            ->reorderable('sort')
            ->defaultSort('sort');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListGifts::route('/'),
            'create' => Pages\CreateGift::route('/create'),
            'edit'   => Pages\EditGift::route('/{record}/edit'),
        ];
    }
}
