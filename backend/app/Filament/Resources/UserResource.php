<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use App\Services\StorageConfigService;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Grid as FormGrid;
use Filament\Forms\Components\Section as FormSection;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Form;
use Filament\Infolists\Components\Grid;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\Section;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Infolist;
use Filament\Tables\Actions\Action;
use Filament\Tables\Actions\ActionGroup;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Actions\ViewAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

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
        return $form->schema([
            FormSection::make(__('admin.account_info'))->schema([
                FormGrid::make(2)->schema([
                    // Avatar lives on the profile relation; the page hooks
                    // (Create/EditUser) route this to profile.avatar, not the
                    // shadowed users.avatar column. Same disk + dir as the API.
                    FileUpload::make('avatar')
                        ->label(__('admin.avatar'))
                        ->avatar()
                        ->image()
                        ->imageEditor()
                        ->maxSize(5120)
                        ->disk('app_storage')
                        ->directory('avatars')
                        ->columnSpanFull(),
                    // UID is mandatory — a user can never be created without one.
                    TextInput::make('uuid')
                        ->label(__('admin.uuid'))
                        ->required()
                        ->unique(ignoreRecord: true)
                        ->maxLength(255),
                    TextInput::make('name')
                        ->label(__('admin.name'))
                        ->maxLength(255),
                    TextInput::make('email')
                        ->label(__('admin.email'))
                        ->email()
                        ->unique(ignoreRecord: true)
                        ->maxLength(255),
                    TextInput::make('phone')
                        ->label(__('admin.phone'))
                        ->tel()
                        ->unique(ignoreRecord: true)
                        ->maxLength(255),
                    // Hashed by the model mutator. Blank on edit keeps the
                    // existing password (dehydrated only when filled).
                    TextInput::make('password')
                        ->label(__('admin.password'))
                        ->password()
                        ->revealable()
                        ->dehydrated(fn($state) => filled($state))
                        ->maxLength(255),
                    Select::make('gender')
                        ->label(__('admin.gender'))
                        ->options([1 => __('admin.male'), 2 => __('admin.female')]),
                    DatePicker::make('birthday')->label(__('admin.birthday')),
                    Select::make('country_id')
                        ->label(__('admin.country'))
                        ->relationship('country', 'name')
                        ->searchable()
                        ->preload(),
                    Toggle::make('status')
                        ->label(__('admin.active'))
                        ->default(true),
                    Textarea::make('bio')
                        ->label(__('admin.bio'))
                        ->columnSpanFull(),
                ]),
            ]),
        ]);
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
                        // Same driver-aware resolution as the table (see above).
                        ->getStateUsing(fn($record) => filled($u = app(StorageConfigService::class)->webUrl($record->avatar)) ? url($u) : null)
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
            // Eager-load the profile (backs the avatar accessor) to avoid N+1.
            ->modifyQueryUsing(fn($query) => $query->with(['country', 'profile']))
            ->columns([
                ImageColumn::make('avatar')
                    ->circular()
                    ->label('')
                    // Resolve through the shared driver-aware seam (absolute cloud
                    // URL for GCS/S3, dashboard-host URL for the local public disk),
                    // NOT Filament's default disk — which is 'public' and would emit
                    // the emulator's STORAGE_PUBLIC_URL host (10.0.2.2) the admin
                    // browser can't reach. url() keeps it a valid absolute URL.
                    ->getStateUsing(fn($record) => filled($u = app(StorageConfigService::class)->webUrl($record->avatar)) ? url($u) : null)
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
                Filter::make('name')
                    ->form([TextInput::make('name')->label(__('admin.name'))])
                    ->query(fn($query, array $data) => $query->when(
                        $data['name'] ?? null,
                        fn($q, $v) => $q->where('name', 'like', "%{$v}%"),
                    )),
                Filter::make('uuid')
                    ->form([TextInput::make('uuid')->label(__('admin.uuid'))])
                    ->query(fn($query, array $data) => $query->when(
                        $data['uuid'] ?? null,
                        fn($q, $v) => $q->where('uuid', 'like', "%{$v}%"),
                    )),
                Filter::make('email')
                    ->form([TextInput::make('email')->label(__('admin.email'))])
                    ->query(fn($query, array $data) => $query->when(
                        $data['email'] ?? null,
                        fn($q, $v) => $q->where('email', 'like', "%{$v}%"),
                    )),
                TernaryFilter::make('status')
                    ->label(__('admin.status'))
                    ->trueLabel(__('admin.active'))
                    ->falseLabel(__('admin.banned')),
            ])
            ->actions([
                // One trigger (⋮) that opens a dropdown with all row actions,
                // instead of crowding them inline next to each user.
                ActionGroup::make([
                    ViewAction::make()->label(__('admin.profile')),
                    EditAction::make(),
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
                    DeleteAction::make(),
                ]),
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
            'index'  => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'view'   => Pages\ViewUser::route('/{record}'),
            'edit'   => Pages\EditUser::route('/{record}/edit'),
        ];
    }

    // Create / edit / delete are gated by the permission system in BaseResource
    // (users.create | users.update | users.delete) — super_admin always passes.
}
