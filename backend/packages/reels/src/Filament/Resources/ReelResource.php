<?php

namespace Utd\Reels\Filament\Resources;

use App\Filament\Resources\BaseResource;
use Filament\Forms\Form;
use Filament\Infolists\Components\Grid;
use Filament\Infolists\Components\Section;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Infolist;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Utd\Reels\Entities\Real;
use Utd\Reels\Filament\Resources\ReelResource\Pages;

class ReelResource extends BaseResource
{
    protected static ?string $model = Real::class;

    protected static ?string $packageSlug = 'reels';
    // Roles & Permissions group (auto-discovered by utd:sync-packages).
    protected static ?string $permissionPrefix = 'reels';
    protected static array $permissionAbilities = ['view', 'delete'];

    protected static ?string $navigationIcon = 'heroicon-o-film';

    // Hidden from the nav: the TikTok-style ReelsFeed page is the main "Reels"
    // view now. This resource is kept only for its record View/Delete routes.
    protected static bool $shouldRegisterNavigation = false;

    public static function getNavigationGroup(): ?string
    {
        return __('reels::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('reels::admin.reels');
    }

    public static function getModelLabel(): string
    {
        return __('reels::admin.reel');
    }

    public static function getPluralModelLabel(): string
    {
        return __('reels::admin.reels');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist->schema([
            Section::make(__('reels::admin.reel'))->schema([
                Grid::make(2)->schema([
                    TextEntry::make('id')->label('ID'),
                    TextEntry::make('user.name')->label(__('reels::admin.owner')),
                    TextEntry::make('description')->label(__('reels::admin.description'))->columnSpanFull(),
                    TextEntry::make('url')->label(__('reels::admin.video'))->columnSpanFull(),
                    TextEntry::make('like_num')->label(__('reels::admin.likes')),
                    TextEntry::make('comment_num')->label(__('reels::admin.comments')),
                    TextEntry::make('view_num')->label(__('reels::admin.views')),
                    TextEntry::make('created_at')->label(__('reels::admin.created_at'))->dateTime(),
                ]),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            // Counts read from the denormalized columns (no per-row withCount).
            ->modifyQueryUsing(fn ($query) => $query->with('user'))
            ->columns([
                TextColumn::make('id')->label('ID')->sortable()->searchable(),
                TextColumn::make('user.name')->label(__('reels::admin.owner'))->searchable(),
                TextColumn::make('description')->label(__('reels::admin.description'))->limit(50)->wrap(),
                TextColumn::make('like_num')->label(__('reels::admin.likes'))->sortable(),
                TextColumn::make('comment_num')->label(__('reels::admin.comments'))->sortable(),
                TextColumn::make('view_num')->label(__('reels::admin.views'))->sortable(),
                TextColumn::make('created_at')->label(__('reels::admin.created_at'))->dateTime()->sortable(),
            ])
            ->actions([
                ViewAction::make(),
                DeleteAction::make(),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListReels::route('/'),
            'view'  => Pages\ViewReel::route('/{record}'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit($record): bool
    {
        return false;
    }
}
