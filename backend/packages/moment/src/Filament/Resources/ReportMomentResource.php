<?php

namespace Utd\Moment\Filament\Resources;

use App\Filament\Resources\BaseResource;
use App\Filament\Resources\UserResource;
use App\Filament\Tables\Columns\UserColumn;
use Filament\Forms\Form;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ViewColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\ReportMoment;
use Utd\Moment\Filament\Resources\ReportMomentResource\Pages;

class ReportMomentResource extends BaseResource
{
    protected static ?string $model = ReportMoment::class;

    protected static ?string $packageSlug = 'moment';
    protected static ?string $permissionPrefix = 'moment_reports';
    protected static array $permissionAbilities = ['view', 'delete'];

    protected static ?string $navigationIcon = 'heroicon-o-flag';

    public static function getNavigationGroup(): ?string
    {
        return __('moment::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('moment::admin.reports');
    }

    public static function getModelLabel(): string
    {
        return __('moment::admin.report');
    }

    public static function getPluralModelLabel(): string
    {
        return __('moment::admin.reports');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function getEloquentQuery(): Builder
    {
        // Eager-load the relations the table previews (post + its first image,
        // reporter, reported user) to avoid N+1 per row.
        return parent::getEloquentQuery()->with(['moment.images', 'reporter.profile', 'reportedUser.profile']);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),

                // Reported post — thumbnail + text snippet (+ #id) in one column.
                ViewColumn::make('post')
                    ->label(__('moment::admin.post'))
                    ->view('moment::filament.tables.post-cell')
                    ->searchable(query: fn (Builder $query, string $search): Builder => $query->whereHas(
                        'moment',
                        fn (Builder $q) => $q->where('description', 'like', "%{$search}%")
                    )),

                // Reporter — avatar + name + copyable UID in one column; click → profile.
                UserColumn::make('reporter')
                    ->label(__('moment::admin.reporter'))
                    ->url(fn (ReportMoment $record) => $record->reporter && UserResource::canAccess()
                        ? UserResource::getUrl('view', ['record' => $record->reporter->getKey()])
                        : null)
                    ->searchable(query: fn (Builder $query, string $search): Builder => $query->whereHas(
                        'reporter',
                        fn (Builder $q) => $q->where('name', 'like', "%{$search}%")->orWhere('uuid', 'like', "%{$search}%")
                    )),

                // Reported user (post owner) — avatar + name + copyable UID; click → profile.
                UserColumn::make('reportedUser')
                    ->label(__('moment::admin.reported'))
                    ->url(fn (ReportMoment $record) => $record->reportedUser && UserResource::canAccess()
                        ? UserResource::getUrl('view', ['record' => $record->reportedUser->getKey()])
                        : null)
                    ->searchable(query: fn (Builder $query, string $search): Builder => $query->whereHas(
                        'reportedUser',
                        fn (Builder $q) => $q->where('name', 'like', "%{$search}%")->orWhere('uuid', 'like', "%{$search}%")
                    )),

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
                Action::make('deleteMoment')
                    ->label(__('moment::admin.delete_moment'))
                    ->color('danger')
                    ->icon('heroicon-o-trash')
                    ->requiresConfirmation()
                    ->action(function (ReportMoment $record) {
                        Moment::where('id', $record->moment_id)->delete();
                        $record->delete();
                    }),
                Action::make('dismiss')
                    ->label(__('moment::admin.dismiss'))
                    ->color('gray')
                    ->icon('heroicon-o-x-mark')
                    ->requiresConfirmation()
                    ->action(fn (ReportMoment $record) => $record->delete()),
            ])
            ->defaultSort('created_at', 'desc');
    }

    /** Resolve a stored media path to a URL (full URLs pass through). */
    public static function resolveImageUrl(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        return Str::startsWith($path, ['http://', 'https://'])
            ? $path
            : Storage::disk('public')->url(ltrim($path, '/'));
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListReportMoments::route('/'),
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
