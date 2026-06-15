<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms\Form;
use Filament\Infolists\Components\Grid;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\Section;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Infolist;
use Filament\Tables\Actions\Action;
use Filament\Tables\Actions\ViewAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;

class UserResource extends BaseResource
{
    protected static ?string $model = User::class;
    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?int $navigationSort = 1;

    // Access is permission-based: users.view to see, users.ban for the ban action.
    protected static ?string $permissionPrefix = 'users';

    public static function getNavigationLabel(): string { return __('admin.nav_users'); }
    public static function getModelLabel(): string { return __('admin.user'); }
    public static function getPluralModelLabel(): string { return __('admin.nav_users'); }

    public static function form(Form $form): Form
    {
        return $form->schema([]);
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        // A package (Profile) may own the profile view: when it registers a
        // builder it takes over; otherwise we fall back to the default schema.
        $registry = app(\App\Support\UserProfileInfolistRegistry::class);
        if ($registry->has()) {
            return ($registry->resolve())($infolist);
        }

        return $infolist->schema([
            Section::make(__('admin.profile'))->schema([
                Grid::make(3)->schema([
                    ImageEntry::make('avatar')
                        ->circular()
                        ->label(__('admin.avatar'))
                        ->defaultImageUrl(fn() => 'https://ui-avatars.com/api/?background=random'),
                    TextEntry::make('id')->label(__('admin.id')),
                    TextEntry::make('uuid')->label(__('admin.uuid'))->copyable(),
                ]),
            ]),

            Section::make(__('admin.account_info'))->schema([
                Grid::make(2)->schema([
                    TextEntry::make('name')->label(__('admin.name')),
                    TextEntry::make('email')->label(__('admin.email'))->copyable(),
                    TextEntry::make('phone')->label(__('admin.phone')),
                    TextEntry::make('gender')
                        ->label(__('admin.gender'))
                        ->formatStateUsing(fn($state) => match($state) {
                            1 => __('admin.male'),
                            2 => __('admin.female'),
                            default => '—'
                        }),
                    TextEntry::make('birthday')->label(__('admin.birthday'))->date(),
                    TextEntry::make('bio')->label(__('admin.bio'))->columnSpanFull(),
                ]),
            ]),

            Section::make(__('admin.admin_section'))->schema([
                Grid::make(2)->schema([
                    TextEntry::make('status')
                        ->label(__('admin.status'))
                        ->badge()
                        ->formatStateUsing(fn($state) => $state ? __('admin.active') : __('admin.banned'))
                        ->color(fn($state) => $state ? 'success' : 'danger'),
                    TextEntry::make('created_at')->label(__('admin.joined'))->dateTime(),
                    TextEntry::make('country.name')->label(__('admin.country')),
                ]),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn($query) => $query->with('country'))
            ->columns([
                ImageColumn::make('avatar')
                    ->circular()
                    ->label('')
                    ->defaultImageUrl(fn($record) => 'https://ui-avatars.com/api/?name=' . urlencode($record->name ?? 'U') . '&background=random'),
                TextColumn::make('id')->label(__('admin.id'))->sortable()->searchable(),
                TextColumn::make('uuid')->label(__('admin.uuid'))->copyable()->limit(12),
                TextColumn::make('name')->label(__('admin.name'))->searchable()->sortable(),
                TextColumn::make('email')->label(__('admin.email'))->searchable()->sortable(),
                TextColumn::make('country.name')->label(__('admin.country')),
                TextColumn::make('created_at')->label(__('admin.joined'))->date()->sortable(),
                IconColumn::make('status')->label(__('admin.active'))->boolean(),
            ])
            ->filters([
                TernaryFilter::make('status')
                    ->label(__('admin.status'))
                    ->trueLabel(__('admin.active'))
                    ->falseLabel(__('admin.banned')),
            ])
            ->actions([
                ViewAction::make()->label(__('admin.profile')),
                Action::make('ban')
                    ->label(__('admin.ban'))
                    ->color('danger')
                    ->icon('heroicon-o-no-symbol')
                    ->requiresConfirmation()
                    ->visible(fn(User $record) => $record->status == 1
                        && (filament()->auth()->user()?->can('users.ban') ?? false))
                    ->action(fn(User $record) => $record->update(['status' => 0])),
                Action::make('unban')
                    ->label(__('admin.unban'))
                    ->color('success')
                    ->icon('heroicon-o-check-circle')
                    ->requiresConfirmation()
                    ->visible(fn(User $record) => $record->status == 0
                        && (filament()->auth()->user()?->can('users.ban') ?? false))
                    ->action(fn(User $record) => $record->update(['status' => 1])),
            ])
            ->defaultSort('created_at', 'desc');
    }

    // Tabs (RelationManagers) contributed by packages via the base registry —
    // keeps the User profile extensible without base depending on any package.
    public static function getRelations(): array
    {
        return app(\App\Support\UserProfileTabRegistry::class)->all();
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'view'  => Pages\ViewUser::route('/{record}'),
        ];
    }

    // Users are managed read-only (+ ban/unban); access gated by users.view
    // via BaseResource. Creating/editing/deleting users from the panel is off.
    public static function canCreate(): bool { return false; }
    public static function canEdit(Model $record): bool { return false; }
    public static function canDelete(Model $record): bool { return false; }
}
