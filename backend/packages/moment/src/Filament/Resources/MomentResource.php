<?php

namespace Utd\Moment\Filament\Resources;

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
use Utd\Moment\Entities\Moment;
use Utd\Moment\Filament\Resources\MomentResource\Pages;

class MomentResource extends BaseResource
{
    protected static ?string $model = Moment::class;

    protected static ?string $packageSlug = 'moment';
    // Roles & Permissions group (auto-discovered by utd:sync-packages).
    protected static ?string $permissionPrefix = 'moments';
    protected static array $permissionAbilities = ['view', 'delete'];

    protected static ?string $navigationIcon = 'heroicon-o-photo';

    // Hidden from the nav: the Facebook-style MomentFeed page is the main "Moments"
    // view now. This resource is kept only for its record View/Delete routes.
    protected static bool $shouldRegisterNavigation = false;

    public static function getNavigationGroup(): ?string
    {
        return __('moment::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('moment::admin.moments');
    }

    public static function getModelLabel(): string
    {
        return __('moment::admin.moment');
    }

    public static function getPluralModelLabel(): string
    {
        return __('moment::admin.moments');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist->schema([
            Section::make(__('moment::admin.moment'))->schema([
                Grid::make(2)->schema([
                    TextEntry::make('id')->label('ID'),
                    TextEntry::make('user.name')->label(__('moment::admin.owner')),
                    TextEntry::make('description')->label(__('moment::admin.description'))->columnSpanFull(),
                    TextEntry::make('likes_count')->label(__('moment::admin.likes'))->state(fn (Moment $r) => $r->likes()->count()),
                    TextEntry::make('comments_count')->label(__('moment::admin.comments'))->state(fn (Moment $r) => $r->comments()->count()),
                    TextEntry::make('reports_count')->label(__('moment::admin.post_reports'))->badge()->color('danger')->state(fn (Moment $r) => $r->reports()->count()),
                    TextEntry::make('comment_reports_count')->label(__('moment::admin.comment_reports_count'))->badge()->color('warning')->state(fn (Moment $r) => $r->commentReports()->count()),
                    TextEntry::make('created_at')->label(__('moment::admin.created_at'))->dateTime(),
                ]),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn ($query) => $query->with('user')->withCount(['likes', 'comments', 'reports', 'commentReports']))
            ->columns([
                TextColumn::make('id')->label('ID')->sortable()->searchable(),
                TextColumn::make('user.name')->label(__('moment::admin.owner'))->searchable(),
                TextColumn::make('description')->label(__('moment::admin.description'))->limit(50)->wrap(),
                TextColumn::make('likes_count')->label(__('moment::admin.likes'))->sortable(),
                TextColumn::make('comments_count')->label(__('moment::admin.comments'))->sortable(),
                TextColumn::make('reports_count')->label(__('moment::admin.post_reports'))->badge()->color('danger')->sortable(),
                TextColumn::make('comment_reports_count')->label(__('moment::admin.comment_reports_count'))->badge()->color('warning')->sortable(),
                TextColumn::make('created_at')->label(__('moment::admin.created_at'))->dateTime()->sortable(),
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
            'index' => Pages\ListMoments::route('/'),
            'view'  => Pages\ViewMoment::route('/{record}'),
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
