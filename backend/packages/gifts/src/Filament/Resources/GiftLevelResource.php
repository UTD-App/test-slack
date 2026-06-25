<?php

namespace Utd\Gifts\Filament\Resources;

use App\Filament\Resources\BaseResource;
use Filament\Forms\Components\ColorPicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Tables\Actions\BulkActionGroup;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\DeleteBulkAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ViewColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Utd\Gifts\Filament\Resources\GiftLevelResource\Pages;
use Utd\Gifts\Models\GiftLevel;

/**
 * Admin CRUD for sender/receiver level badges. One resource, two tabs (sender /
 * receiver) on the list page. Each level is an icon + an EXP threshold; a user's
 * level is the highest threshold their accumulated exp reaches (see GiftLevelService).
 */
class GiftLevelResource extends BaseResource
{
    protected static ?string $packageSlug = 'gifts';
    protected static ?string $permissionPrefix = 'gift_levels';

    protected static ?string $model = GiftLevel::class;
    protected static ?string $navigationIcon = 'heroicon-o-trophy';
    protected static ?int $navigationSort = 4;

    public static function getNavigationLabel(): string { return __('gifts::admin.nav_levels'); }
    public static function getModelLabel(): string { return __('gifts::admin.level'); }
    public static function getPluralModelLabel(): string { return __('gifts::admin.nav_levels'); }
    public static function getNavigationGroup(): ?string { return __('gifts::admin.nav_gifts_group'); }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Select::make('kind')
                ->label(__('gifts::admin.kind'))
                ->options([
                    GiftLevel::KIND_SENDER   => __('gifts::admin.kind_sender'),
                    GiftLevel::KIND_RECEIVER => __('gifts::admin.kind_receiver'),
                ])
                ->default(GiftLevel::KIND_SENDER)
                ->required(),
            TextInput::make('level')->label(__('gifts::admin.level_number'))
                ->numeric()->minValue(1)->required(),
            TextInput::make('threshold')->label(__('gifts::admin.threshold'))
                ->numeric()->minValue(0)->default(0)->required()
                ->helperText(__('gifts::admin.threshold_hint')),
            TextInput::make('title.en')->label(__('gifts::admin.title_en'))->required()->maxLength(100),
            TextInput::make('title.ar')->label(__('gifts::admin.title_ar'))->maxLength(100),
            FileUpload::make('img')->label(__('gifts::admin.level_icon'))
                ->disk('public')
                ->directory('gifts/levels')
                ->visibility('public')
                ->acceptedFileTypes(['image/png', 'image/jpeg', 'image/gif', 'image/svg+xml', 'application/json', 'application/octet-stream'])
                ->maxSize(4096)
                ->helperText(__('gifts::admin.level_icon_hint')),
            ColorPicker::make('color')->label(__('gifts::admin.level_color')),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                ViewColumn::make('img')->label('')->view('gifts::filament.columns.gift-level-icon'),
                TextColumn::make('id')->label('ID')->sortable(),
                TextColumn::make('kind')->label(__('gifts::admin.kind'))->badge()
                    ->formatStateUsing(fn ($state) => $state === GiftLevel::KIND_RECEIVER
                        ? __('gifts::admin.kind_receiver')
                        : __('gifts::admin.kind_sender'))
                    ->color(fn ($state) => $state === GiftLevel::KIND_RECEIVER ? 'success' : 'info'),
                TextColumn::make('level')->label(__('gifts::admin.level_number'))->sortable(),
                TextColumn::make('threshold')->label(__('gifts::admin.threshold'))->numeric()->sortable(),
                TextColumn::make('title')->label(__('gifts::admin.level_title'))
                    ->formatStateUsing(fn ($state) => is_array($state) ? ($state['ar'] ?? $state['en'] ?? reset($state)) : $state),
            ])
            ->filters([
                SelectFilter::make('kind')
                    ->label(__('gifts::admin.kind'))
                    ->options([
                        GiftLevel::KIND_SENDER   => __('gifts::admin.kind_sender'),
                        GiftLevel::KIND_RECEIVER => __('gifts::admin.kind_receiver'),
                    ]),
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
            ->defaultSort('level');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListGiftLevels::route('/'),
            'create' => Pages\CreateGiftLevel::route('/create'),
            'edit'   => Pages\EditGiftLevel::route('/{record}/edit'),
        ];
    }
}
