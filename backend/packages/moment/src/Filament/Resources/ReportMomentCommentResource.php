<?php

namespace Utd\Moment\Filament\Resources;

use App\Filament\Resources\BaseResource;
use App\Filament\Resources\UserResource;
use App\Filament\Tables\Columns\UserColumn;
use Filament\Forms\Form;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Utd\Moment\Entities\MomentComment;
use Utd\Moment\Entities\ReportMomentComment;
use Utd\Moment\Filament\Resources\ReportMomentCommentResource\Pages;

class ReportMomentCommentResource extends BaseResource
{
    protected static ?string $model = ReportMomentComment::class;

    protected static ?string $packageSlug = 'moment';
    protected static ?string $permissionPrefix = 'moment_comment_reports';
    protected static array $permissionAbilities = ['view', 'delete'];

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-ellipsis';

    public static function getNavigationGroup(): ?string
    {
        return __('moment::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('moment::admin.comment_reports');
    }

    public static function getModelLabel(): string
    {
        return __('moment::admin.comment_report');
    }

    public static function getPluralModelLabel(): string
    {
        return __('moment::admin.comment_reports');
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

                // Reported comment text (+ the moment it belongs to).
                TextColumn::make('comment.comment')
                    ->label(__('moment::admin.comment'))
                    ->limit(60)
                    ->wrap()
                    ->description(fn (ReportMomentComment $record) => '#'.$record->moment_id)
                    ->searchable(query: fn (Builder $query, string $search): Builder => $query->whereHas(
                        'comment',
                        fn (Builder $q) => $q->where('comment', 'like', "%{$search}%")
                    )),

                UserColumn::make('reporter')
                    ->label(__('moment::admin.reporter'))
                    ->url(fn (ReportMomentComment $record) => $record->reporter && UserResource::canAccess()
                        ? UserResource::getUrl('view', ['record' => $record->reporter->getKey()])
                        : null),

                UserColumn::make('reportedUser')
                    ->label(__('moment::admin.reported'))
                    ->url(fn (ReportMomentComment $record) => $record->reportedUser && UserResource::canAccess()
                        ? UserResource::getUrl('view', ['record' => $record->reportedUser->getKey()])
                        : null),

                TextColumn::make('type')
                    ->label(__('moment::admin.type'))
                    ->badge()
                    ->formatStateUsing(function (?string $state) {
                        if (! $state) {
                            return $state;
                        }
                        $key = "moment::admin.report_{$state}";
                        $label = __($key);

                        return $label === $key ? ucfirst($state) : $label;
                    }),
                TextColumn::make('description')->label(__('moment::admin.reason'))->limit(50)->wrap(),
                TextColumn::make('created_at')->label(__('moment::admin.created_at'))->dateTime()->sortable(),
            ])
            ->actions([
                Action::make('deleteComment')
                    ->label(__('moment::admin.delete_comment'))
                    ->color('danger')
                    ->icon('heroicon-o-trash')
                    ->requiresConfirmation()
                    ->action(function (ReportMomentComment $record) {
                        // Remove the comment and its replies; the report row
                        // cascades away with the comment (FK cascadeOnDelete).
                        MomentComment::where('parent_id', $record->comment_id)->delete();
                        MomentComment::where('id', $record->comment_id)->delete();
                        $record->delete();
                    }),
                Action::make('dismiss')
                    ->label(__('moment::admin.dismiss'))
                    ->color('gray')
                    ->icon('heroicon-o-x-mark')
                    ->requiresConfirmation()
                    ->action(fn (ReportMomentComment $record) => $record->delete()),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListReportMomentComments::route('/'),
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
