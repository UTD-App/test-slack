<?php

namespace Utd\Moment\Filament\Resources\UserResource\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ViewColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * "Reports filed" tab on the base User profile (UserResource view page).
 *
 * Lists the moment reports THIS user submitted (report_moments.Reporter_id),
 * each linked to the Moment it targets. Wired cross-package WITHOUT base knowing
 * about this package: the Moment provider injects a `momentReportsFiled` relation
 * onto the base User via resolveRelationUsing(), then registers this class with
 * the base UserProfileTabRegistry. Read-only.
 */
class MomentReportsFiledRelationManager extends RelationManager
{
    protected static string $relationship = 'momentReportsFiled';

    // Render inline with the page (not lazy). Filament's lazy default loads on
    // x-INTERSECT (scroll into view); under the tall profile infolist the active
    // tab sits below the fold and never loads until scrolled. Only the active tab
    // ever renders (and it's paginated), so eager loading costs nothing here.
    protected static bool $isLazy = false;

    public static function getTitle(Model $ownerRecord, string $pageClass): string
    {
        return __('moment::admin.reports_filed_tab');
    }

    public static function getBadge(Model $ownerRecord, string $pageClass): ?string
    {
        return (string) $ownerRecord->momentReportsFiled()->count();
    }

    public function isReadOnly(): bool
    {
        return true;
    }

    public function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with('moment.images'))
            ->columns([
                // Target post — thumbnail + snippet (+ #id). Reuses the reports
                // resource cell, which only reads $record->moment / moment_id.
                ViewColumn::make('post')
                    ->label(__('moment::admin.post'))
                    ->view('moment::filament.tables.post-cell'),

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
            ->defaultSort('created_at', 'desc');
    }
}
