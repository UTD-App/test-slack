<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AdminUserResource\Pages;
use App\Models\AdminRole;
use App\Models\AdminUser;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables\Actions\Action;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Hash;

class AdminUserResource extends Resource
{
    protected static ?string $model = AdminUser::class;
    protected static ?string $navigationIcon = 'heroicon-o-shield-check';
    protected static ?string $navigationLabel = null;
    protected static ?int $navigationSort = 5;

    public static function getModelLabel(): string { return __('admin.administrator'); }
    public static function getPluralModelLabel(): string { return __("admin.nav_admin_users"); }

    public static function canAccess(): bool
    {
        return filament()->auth()->user()?->isSuperAdmin() ?? false;
    }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Section::make()->schema([
                TextInput::make('name')->label(__('admin.name'))->required(),
                TextInput::make('email')->label(__('admin.email'))->email()->required()->unique(ignoreRecord: true),
                TextInput::make('password')
                    ->label(__('admin.password'))
                    ->password()
                    ->revealable()
                    ->required(fn($record) => $record === null)
                    ->minLength(8)
                    ->dehydrateStateUsing(fn($state) => !empty($state) ? Hash::make($state) : null)
                    ->dehydrated(fn($state) => !empty($state)),
                Toggle::make('is_active')->label(__('admin.active'))->default(true),
            ])->columns(2),

            Section::make(__('admin.roles_section'))->schema([
                CheckboxList::make('roles')
                    ->relationship('roles', 'label')
                    ->columns(2),
            ]),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                ImageColumn::make('avatar')->circular()->label(''),
                TextColumn::make('name')->label(__('admin.name'))->searchable()->sortable(),
                TextColumn::make('email')->label(__('admin.email'))->searchable()->sortable(),
                IconColumn::make('is_active')->label(__('admin.active'))->boolean(),
                TextColumn::make('created_at')->label(__('admin.created_at'))->date()->sortable(),
            ])
            ->actions([
                Action::make('deactivate')
                    ->label(__('admin.deactivate'))
                    ->color('warning')
                    ->icon('heroicon-o-lock-closed')
                    ->requiresConfirmation()
                    ->visible(fn(AdminUser $r) => $r->is_active)
                    ->action(fn(AdminUser $r) => $r->update(['is_active' => false])),
                Action::make('activate')
                    ->label(__('admin.activate'))
                    ->color('success')
                    ->icon('heroicon-o-lock-open')
                    ->requiresConfirmation()
                    ->visible(fn(AdminUser $r) => !$r->is_active)
                    ->action(fn(AdminUser $r) => $r->update(['is_active' => true])),
                DeleteAction::make(),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListAdminUsers::route('/'),
            'create' => Pages\CreateAdminUser::route('/create'),
            'edit'   => Pages\EditAdminUser::route('/{record}/edit'),
        ];
    }
}
