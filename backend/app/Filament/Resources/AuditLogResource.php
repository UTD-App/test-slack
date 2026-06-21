<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AuditLogResource\Pages;
use App\Models\AuditLog;
use Filament\Infolists\Components\Section as InfoSection;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Infolist;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

/**
 * Read-only admin audit trail. Writes happen automatically (via the Auditable
 * trait on sensitive models) or through Audit::log(); this resource only lists
 * and views them. Exposes a single `audit.view` permission.
 */
class AuditLogResource extends BaseResource
{
    protected static ?string $model = AuditLog::class;
    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-list';
    protected static ?int $navigationSort = 90;

    protected static ?string $permissionPrefix = 'audit';
    protected static array $permissionAbilities = ['view'];

    public static function getModelLabel(): string { return __('admin.audit_log'); }
    public static function getPluralModelLabel(): string { return __('admin.audit_logs'); }
    public static function getNavigationLabel(): string { return __('admin.nav_audit_log'); }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('id', 'desc')
            ->columns([
                TextColumn::make('created_at')->label(__('admin.audit_when'))->dateTime()->sortable(),
                TextColumn::make('adminUser.name')->label(__('admin.audit_admin'))->default('—')->searchable(),
                TextColumn::make('action')->label(__('admin.audit_action'))->badge()->searchable(),
                TextColumn::make('auditable_type')
                    ->label(__('admin.audit_subject'))
                    ->formatStateUsing(fn (?string $state) => $state ? class_basename($state) : '—')
                    ->description(fn (AuditLog $r) => $r->auditable_id ? "#{$r->auditable_id}" : null),
                TextColumn::make('description')->label(__('admin.audit_description'))->limit(50)->placeholder('—'),
                TextColumn::make('ip')->label(__('admin.audit_ip'))->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('action')->label(__('admin.audit_action'))
                    ->options(fn () => AuditLog::query()->distinct()->orderBy('action')->pluck('action', 'action')->all()),
            ]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist->schema([
            InfoSection::make()->schema([
                TextEntry::make('created_at')->label(__('admin.audit_when'))->dateTime(),
                TextEntry::make('adminUser.name')->label(__('admin.audit_admin'))->default('—'),
                TextEntry::make('action')->label(__('admin.audit_action'))->badge(),
                TextEntry::make('auditable_type')->label(__('admin.audit_subject'))
                    ->formatStateUsing(fn (?string $state) => $state ? class_basename($state) : '—'),
                TextEntry::make('auditable_id')->label(__('admin.audit_subject_id'))->placeholder('—'),
                TextEntry::make('description')->label(__('admin.audit_description'))->placeholder('—')->columnSpanFull(),
                TextEntry::make('ip')->label(__('admin.audit_ip'))->placeholder('—'),
                TextEntry::make('user_agent')->label(__('admin.audit_user_agent'))->placeholder('—')->columnSpanFull(),
                TextEntry::make('changes')
                    ->label(__('admin.audit_changes'))
                    ->formatStateUsing(fn ($state) => $state ? json_encode($state, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : '—')
                    ->columnSpanFull(),
            ])->columns(2),
        ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListAuditLogs::route('/'),
            'view'  => Pages\ViewAuditLog::route('/{record}'),
        ];
    }
}
