<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PackageResource\Pages;
use App\Models\Package;
use Filament\Notifications\Notification;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class PackageResource extends BaseResource
{
    protected static ?string $model = Package::class;
    protected static ?string $navigationIcon = 'heroicon-o-puzzle-piece';
    protected static ?int $navigationSort = 30;

    protected static ?string $permissionPrefix = 'packages';

    public static function getNavigationLabel(): string { return __('admin.nav_packages'); }
    public static function getModelLabel(): string { return __('admin.package'); }
    public static function getPluralModelLabel(): string { return __('admin.nav_packages'); }

    public static function table(Table $table): Table
    {
        return $table
            ->reorderable('order')
            ->defaultSort('order')
            ->columns([
                TextColumn::make('name')->label(__('admin.name'))->searchable()->sortable(),
                TextColumn::make('slug')->label(__('admin.slug'))->badge()->color('gray'),
                TextColumn::make('version')->label(__('admin.version'))->badge()->color('info'),
                IconColumn::make('is_core')->label(__('admin.core'))->boolean(),
                IconColumn::make('enabled')
                    ->label(__('admin.status'))
                    ->boolean()
                    ->trueIcon('heroicon-o-check-circle')
                    ->falseIcon('heroicon-o-x-circle')
                    ->trueColor('success')
                    ->falseColor('danger'),
                TextColumn::make('installed_at')->label(__('admin.installed_at'))->dateTime()->sortable(),
            ])
            ->actions([
                Action::make('toggleEnabled')
                    ->label(fn (Package $record) => $record->enabled ? __('admin.disable') : __('admin.enable'))
                    ->icon(fn (Package $record) => $record->enabled ? 'heroicon-m-lock-closed' : 'heroicon-m-lock-open')
                    ->color(fn (Package $record) => $record->enabled ? 'danger' : 'success')
                    ->button()
                    ->requiresConfirmation()
                    ->modalDescription(fn (Package $record) => $record->enabled ? __('admin.disable_confirm') : __('admin.enable_confirm'))
                    // Core packages (base) can never be disabled.
                    ->hidden(fn (Package $record) => $record->is_core)
                    ->action(function (Package $record) {
                        $record->enabled = ! $record->enabled;
                        $record->save();

                        Notification::make()
                            ->title($record->enabled ? __('admin.package_enabled') : __('admin.package_disabled'))
                            ->success()
                            ->send();
                    }),
            ])
            ->emptyStateHeading(__('admin.no_packages_yet'))
            ->emptyStateDescription(__('admin.no_packages_hint'));
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPackages::route('/'),
        ];
    }

    // Rows are owned by `utd:sync-packages`; admin only toggles/reorders here.
    public static function canCreate(): bool { return false; }
    public static function canEdit($record): bool { return false; }
    public static function canDelete($record): bool { return ! $record->is_core; }
}
