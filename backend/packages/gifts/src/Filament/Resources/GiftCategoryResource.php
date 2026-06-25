<?php

namespace Utd\Gifts\Filament\Resources;

use App\Filament\Resources\BaseResource;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Tables\Actions\BulkActionGroup;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\DeleteBulkAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Utd\Gifts\Filament\Resources\GiftCategoryResource\Pages;
use Utd\Gifts\Models\GiftCategory;

class GiftCategoryResource extends BaseResource
{
    protected static ?string $packageSlug = 'gifts';
    protected static ?string $permissionPrefix = 'gift_categories';

    protected static ?string $model = GiftCategory::class;
    protected static ?string $navigationIcon = 'heroicon-o-rectangle-group';
    protected static ?int $navigationSort = 2;

    public static function getNavigationLabel(): string { return __('gifts::admin.nav_categories'); }
    public static function getModelLabel(): string { return __('gifts::admin.category'); }
    public static function getPluralModelLabel(): string { return __('gifts::admin.nav_categories'); }
    public static function getNavigationGroup(): ?string { return __('gifts::admin.nav_gifts_group'); }

    public static function form(Form $form): Form
    {
        return $form->schema([
            TextInput::make('title.en')->label(__('gifts::admin.title_en'))->required()->maxLength(100),
            TextInput::make('title.ar')->label(__('gifts::admin.title_ar'))->maxLength(100),
            Select::make('type')
                ->label(__('gifts::admin.type'))
                ->options([
                    'normal' => __('gifts::admin.type_normal'),
                    'lucky'  => __('gifts::admin.type_lucky'),
                    'cp'     => __('gifts::admin.type_cp'),
                ])
                ->default('normal')
                ->required(),
            TextInput::make('sort')->label(__('gifts::admin.sort'))->numeric()->default(0),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                TextColumn::make('title')
                    ->label(__('gifts::admin.title'))
                    ->formatStateUsing(fn ($state) => is_array($state) ? ($state['en'] ?? reset($state)) : $state),
                TextColumn::make('type')->label(__('gifts::admin.type'))->badge(),
                TextColumn::make('sort')->label(__('gifts::admin.sort'))->sortable(),
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
            // categories endpoint reads (ordered by sort).
            ->reorderable('sort')
            ->defaultSort('sort');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListGiftCategories::route('/'),
            'create' => Pages\CreateGiftCategory::route('/create'),
            'edit'   => Pages\EditGiftCategory::route('/{record}/edit'),
        ];
    }
}
