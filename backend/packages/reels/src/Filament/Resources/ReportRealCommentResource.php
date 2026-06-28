<?php

namespace Utd\Reels\Filament\Resources;

use App\Filament\Resources\BaseResource;
use App\Filament\Resources\UserResource;
use App\Filament\Tables\Columns\UserColumn;
use Filament\Forms\Form;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Utd\Reels\Entities\RealUserComment;
use Utd\Reels\Entities\ReportRealComment;
use Utd\Reels\Filament\Resources\ReportRealCommentResource\Pages;

class ReportRealCommentResource extends BaseResource
{
    protected static ?string $model = ReportRealComment::class;

    protected static ?string $packageSlug = 'reels';
    protected static ?string $permissionPrefix = 'reel_comment_reports';
    protected static array $permissionAbilities = ['view', 'delete'];

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-ellipsis';

    public static function getNavigationGroup(): ?string
    {
        return __('reels::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('reels::admin.comment_reports');
    }

    public static function getModelLabel(): string
    {
        return __('reels::admin.comment_report');
    }

    public static function getPluralModelLabel(): string
    {
        return __('reels::admin.comment_reports');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()->with(['comment', 'reporter.profile', 'reportedUser.profile']);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),

                // Reported comment text (+ the reel it belongs to).
                TextColumn::make('comment.comment')
                    ->label(__('reels::admin.comment'))
                    ->limit(60)
                    ->wrap()
                    ->description(fn (ReportRealComment $record) => '#'.$record->real_id)
                    ->searchable(query: fn (Builder $query, string $search): Builder => $query->whereHas(
                        'comment',
                        fn (Builder $q) => $q->where('comment', 'like', "%{$search}%")
                    )),

                UserColumn::make('reporter')
                    ->label(__('reels::admin.reporter'))
                    ->url(fn (ReportRealComment $record) => $record->reporter && UserResource::canAccess()
                        ? UserResource::getUrl('view', ['record' => $record->reporter->getKey()])
                        : null),

                UserColumn::make('reportedUser')
                    ->label(__('reels::admin.reported'))
                    ->url(fn (ReportRealComment $record) => $record->reportedUser && UserResource::canAccess()
                        ? UserResource::getUrl('view', ['record' => $record->reportedUser->getKey()])
                        : null),

                TextColumn::make('type')
                    ->label(__('reels::admin.type'))
                    ->badge()
                    ->formatStateUsing(function (?string $state) {
                        if (! $state) {
                            return $state;
                        }
                        $key = "reels::admin.report_{$state}";
                        $label = __($key);

                        return $label === $key ? ucfirst($state) : $label;
                    }),
                TextColumn::make('description')->label(__('reels::admin.description'))->limit(50)->wrap(),
                TextColumn::make('created_at')->label(__('reels::admin.created_at'))->dateTime()->sortable(),
            ])
            ->actions([
                Action::make('deleteComment')
                    ->label(__('reels::admin.delete_comment'))
                    ->color('danger')
                    ->icon('heroicon-o-trash')
                    ->requiresConfirmation()
                    ->action(function (ReportRealComment $record) {
                        // Remove the comment and its replies; the report row
                        // cascades away with the comment (FK cascadeOnDelete).
                        RealUserComment::where('parent_id', $record->comment_id)->delete();
                        RealUserComment::where('id', $record->comment_id)->delete();
                        $record->delete();
                    }),
                Action::make('dismiss')
                    ->label(__('reels::admin.dismiss'))
                    ->color('gray')
                    ->icon('heroicon-o-x-mark')
                    ->requiresConfirmation()
                    ->action(fn (ReportRealComment $record) => $record->delete()),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListReportRealComments::route('/'),
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
