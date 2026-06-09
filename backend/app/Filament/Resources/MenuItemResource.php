<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MenuItemResource\Pages;
use App\Models\MenuItem;
use App\Models\Role;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class MenuItemResource extends Resource
{
    protected static ?string $model = MenuItem::class;
    protected static ?string $navigationIcon = 'heroicon-o-bars-3';
    protected static ?int $navigationSort = 31;

    /** UI slots — must mirror Flutter lib/addons/ui_slot.dart */
    public const SLOTS = [
        'bottomNav', 'drawer', 'home', 'appBar', 'dashboard',
        'settings', 'loginMethods', 'userProfile', 'userProfileActions',
    ];

    public static function getNavigationLabel(): string { return __('admin.nav_menu'); }
    public static function getModelLabel(): string { return __('admin.menu_item'); }
    public static function getPluralModelLabel(): string { return __('admin.menu_items'); }

    public static function canAccess(): bool
    {
        return filament()->auth()->user()?->hasAnyRole(['super_admin', 'settings_manager']) ?? false;
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Section::make()->schema([
                TextInput::make('slug')
                    ->label(__('admin.slug'))
                    ->helperText('= Flutter UiContribution.contributionId')
                    ->required()
                    ->maxLength(120)
                    // The slug is the immutable bridge to the Flutter client —
                    // changing it on an existing (often package-seeded) row breaks
                    // the mapping and lets syncDefaults re-insert a duplicate.
                    ->disabledOn('edit'),
                TextInput::make('label_key')->label(__('admin.label_key'))->required(),
                Select::make('slot')
                    ->label(__('admin.slot'))
                    ->options(array_combine(self::SLOTS, self::SLOTS))
                    ->required(),
                Select::make('target')
                    ->label(__('admin.menu_target'))
                    ->options([
                        'app'       => __('admin.target_app'),
                        'dashboard' => __('admin.target_dashboard'),
                        'both'      => __('admin.target_both'),
                    ])
                    ->default('app')
                    ->required(),
                TextInput::make('icon')->label(__('admin.icon')),
                TextInput::make('active_icon')->label(__('admin.active_icon')),
                TextInput::make('route')->label(__('admin.route')),
                TextInput::make('order')->label(__('admin.order'))->numeric()->default(0),
                Select::make('parent_id')
                    ->label(__('admin.parent'))
                    ->relationship('parent', 'slug')
                    ->searchable(),
                Select::make('roles')
                    ->label(__('admin.roles_gate'))
                    ->multiple()
                    ->options(fn () => Role::pluck('display_name', 'key')->toArray()),
                Toggle::make('is_visible')->label(__('admin.visible'))->default(true),
            ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->reorderable('order')
            ->defaultSort('order')
            ->columns([
                TextColumn::make('label_key')->label(__('admin.label_key'))->searchable(),
                TextColumn::make('slug')->label(__('admin.slug'))->badge()->color('gray'),
                TextColumn::make('package')->label(__('admin.package'))->badge()->sortable(),
                TextColumn::make('slot')->label(__('admin.slot'))->badge()->color('info'),
                TextColumn::make('target')->label(__('admin.menu_target'))->badge(),
                ToggleColumn::make('is_visible')->label(__('admin.visible')),
            ])
            ->filters([
                SelectFilter::make('package')
                    ->label(__('admin.package'))
                    ->options(fn () => MenuItem::query()
                        ->distinct()
                        ->orderBy('package')
                        ->pluck('package', 'package')
                        ->toArray()),
                SelectFilter::make('slot')
                    ->label(__('admin.slot'))
                    ->options(array_combine(self::SLOTS, self::SLOTS)),
            ])
            ->emptyStateHeading(__('admin.no_menu_items_yet'))
            ->emptyStateDescription(__('admin.no_menu_items_hint'))
            ->actions([
                EditAction::make(),
                DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListMenuItems::route('/'),
            'create' => Pages\CreateMenuItem::route('/create'),
            'edit'   => Pages\EditMenuItem::route('/{record}/edit'),
        ];
    }
}
