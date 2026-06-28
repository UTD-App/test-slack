<?php

namespace Utd\Reels\Filament\Resources;

use App\Filament\Resources\BaseResource;
use Filament\Forms\Form;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\ReportReals;
use Utd\Reels\Filament\Resources\ReportReelResource\Pages;

class ReportReelResource extends BaseResource
{
    protected static ?string $model = ReportReals::class;

    protected static ?string $packageSlug = 'reels';
    protected static ?string $permissionPrefix = 'reel_reports';
    protected static array $permissionAbilities = ['view', 'delete'];

    protected static ?string $navigationIcon = 'heroicon-o-flag';

    public static function getNavigationGroup(): ?string
    {
        return __('reels::admin.nav_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('reels::admin.reports');
    }

    public static function getModelLabel(): string
    {
        return __('reels::admin.report');
    }

    public static function getPluralModelLabel(): string
    {
        return __('reels::admin.reports');
    }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->label('ID')->sortable(),
                TextColumn::make('real_id')->label(__('reels::admin.reel'))->sortable()->searchable(),
                TextColumn::make('Reporter_id')->label(__('reels::admin.reporter'))->searchable(),
                TextColumn::make('Reported_id')->label(__('reels::admin.reported'))->searchable(),
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
                Action::make('deleteReel')
                    ->label(__('reels::admin.delete_reel'))
                    ->color('danger')
                    ->icon('heroicon-o-trash')
                    ->requiresConfirmation()
                    ->action(function (ReportReals $record) {
                        Real::where('id', $record->real_id)->delete();
                        $record->delete();
                    }),
                Action::make('dismiss')
                    ->label(__('reels::admin.dismiss'))
                    ->color('gray')
                    ->icon('heroicon-o-x-mark')
                    ->requiresConfirmation()
                    ->action(fn (ReportReals $record) => $record->delete()),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListReportReels::route('/'),
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
