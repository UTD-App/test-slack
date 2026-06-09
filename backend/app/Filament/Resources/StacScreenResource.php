<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StacScreenResource\Pages;
use App\Models\StacScreen;
use Filament\Forms\Form;
use Filament\Infolists\Components\Grid;
use Filament\Infolists\Components\Section;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Infolist;
use Filament\Resources\Resource;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class StacScreenResource extends Resource
{
    protected static ?string $model = StacScreen::class;
    protected static ?string $navigationIcon = 'heroicon-o-device-phone-mobile';
    protected static ?int $navigationSort = 25;

    public static function getNavigationLabel(): string { return __('admin.nav_stac'); }
    public static function getModelLabel(): string { return __('admin.screen_name'); }
    public static function getPluralModelLabel(): string { return __('admin.nav_stac'); }
    public static function getNavigationGroup(): ?string { return null; }

    public static function canAccess(): bool
    {
        return filament()->auth()->user()?->hasAnyRole(["super_admin", "settings_manager"]) ?? false;
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist->schema([
            Section::make(__('admin.screen_info'))->schema([
                Grid::make(3)->schema([
                    TextEntry::make('name')->label(__('admin.screen_name')),
                    TextEntry::make('package')->label(__('admin.package'))->badge(),
                    TextEntry::make('version')->label(__('admin.version'))->badge()->color('info'),
                ]),
                TextEntry::make('is_active')->label(__('admin.status'))
                    ->badge()
                    ->formatStateUsing(fn($state) => $state ? __('admin.active') : __('admin.inactive'))
                    ->color(fn($state) => $state ? 'success' : 'danger'),
                TextEntry::make('updated_at')->label(__('admin.last_push_by_studio'))->dateTime(),
            ]),
            Section::make(__('admin.json_content'))
                ->description(__('admin.json_content_hint'))
                ->schema([
                    TextEntry::make('content')
                        ->label('')
                        ->state(fn($record) => json_encode($record->content, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES))
                        ->columnSpanFull()
                        ->extraAttributes([
                            'class' => 'font-mono text-xs whitespace-pre overflow-x-auto bg-gray-950 dark:bg-gray-900 text-green-400 p-4 rounded-xl block',
                            'style' => 'max-height:400px;overflow-y:auto;',
                        ]),
                ])->collapsed(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->label(__('admin.screen_name'))->searchable()->sortable(),
                TextColumn::make('package')->label(__('admin.package'))->badge()->sortable(),
                TextColumn::make('version')->label(__('admin.version'))->badge()->color('info'),
                IconColumn::make('is_active')->label(__('admin.active'))->boolean(),
                TextColumn::make('updated_at')->label(__('admin.last_push'))->dateTime()->sortable(),
            ])
            ->defaultSort('updated_at', 'desc')
            ->emptyStateHeading(__('admin.no_screens_yet'))
            ->emptyStateDescription(__('admin.no_screens_hint'));
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStacScreens::route('/'),
            'view'  => Pages\ViewStacScreen::route('/{record}'),
        ];
    }

    // Read-only — all writes come from UTD Studio via API
    public static function canCreate(): bool { return false; }
    public static function canEdit($record): bool { return false; }
    public static function canDelete($record): bool { return false; }
}
