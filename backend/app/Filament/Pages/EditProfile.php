<?php

namespace App\Filament\Pages;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class EditProfile extends Page
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = null;
    protected static bool $shouldRegisterNavigation = false;
    protected static string $view = 'filament.pages.edit-profile';

    public ?array $data = [];

    // Without this the title is derived from the class name ("Edit Profile")
    // and stays English regardless of locale.
    public function getTitle(): string
    {
        return __('admin.my_profile');
    }

    public function mount(): void
    {
        $user = Auth::guard('admin')->user();
        $this->form->fill([
            'name'   => $user->name,
            'email'  => $user->email,
            'avatar' => $user->avatar,
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Section::make(__('admin.profile_photo'))->schema([
                    FileUpload::make('avatar')
                        ->label('')
                        ->image()
                        ->avatar()
                        ->disk('public')
                        ->directory('admin-avatars')
                        ->maxSize(2048),
                ]),

                Section::make(__('admin.account_info'))->schema([
                    TextInput::make('name')
                        ->label(__('admin.name'))
                        ->required()
                        ->maxLength(255),
                    TextInput::make('email')
                        ->label(__('admin.email'))
                        ->email()
                        ->required()
                        ->maxLength(255),
                ])->columns(2),

                Section::make(__('admin.change_password'))->schema([
                    TextInput::make('current_password')
                        ->label(__('admin.current_password'))
                        ->password()
                        ->revealable(),
                    TextInput::make('new_password')
                        ->label(__('admin.new_password'))
                        ->password()
                        ->revealable()
                        ->minLength(8)
                        ->same('new_password_confirmation'),
                    TextInput::make('new_password_confirmation')
                        ->label(__('admin.confirm_new_password'))
                        ->password()
                        ->revealable(),
                ])->columns(3),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();
        $user = Auth::guard('admin')->user();

        if (!empty($data['current_password'])) {
            if (!Hash::check($data['current_password'], $user->password)) {
                Notification::make()
                    ->title(__('admin.password_incorrect'))
                    ->danger()
                    ->send();
                return;
            }
            if (!empty($data['new_password'])) {
                $user->password = Hash::make($data['new_password']);
            }
        }

        $user->name   = $data['name'];
        $user->email  = $data['email'];
        $user->avatar = $data['avatar'];
        $user->save();

        Notification::make()
            ->title(__('admin.profile_updated'))
            ->success()
            ->send();
    }
}
