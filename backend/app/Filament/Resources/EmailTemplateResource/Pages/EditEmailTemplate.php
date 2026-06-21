<?php

namespace App\Filament\Resources\EmailTemplateResource\Pages;

use App\Filament\Resources\EmailTemplateResource;
use App\Mail\TemplatedMail;
use App\Models\EmailTemplate;
use Filament\Actions\Action;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Support\Facades\Mail;

class EditEmailTemplate extends EditRecord
{
    protected static string $resource = EmailTemplateResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->previewAction(),
            $this->sendTestAction(),
            $this->restoreAction(),
        ];
    }

    /** Render the current (unsaved) English body in an isolated iframe. */
    private function previewAction(): Action
    {
        return Action::make('preview')
            ->label(__('admin.email_template_preview'))
            ->icon('heroicon-o-eye')
            ->color('gray')
            ->modalHeading(__('admin.email_template_preview'))
            ->modalSubmitAction(false)
            ->modalCancelActionLabel(__('admin.close'))
            ->modalContent(function () {
                $data = $this->form->getState();
                $html = $data['body']['en'] ?? '';
                $html = EmailTemplate::applyVars($html, static::sampleVars());

                return view('filament.email-template-preview', ['html' => $html]);
            });
    }

    /** Send the (saved) template to the logged-in admin's own inbox. */
    private function sendTestAction(): Action
    {
        return Action::make('sendTest')
            ->label(__('admin.email_template_send_test'))
            ->icon('heroicon-o-paper-airplane')
            ->action(function () {
                $admin = filament()->auth()->user();

                if (! $admin?->email) {
                    Notification::make()->title(__('admin.email_template_no_admin_email'))->danger()->send();

                    return;
                }

                // Persist current edits first so the test reflects what's on screen.
                $this->save(shouldRedirect: false, shouldSendSavedNotification: false);

                try {
                    Mail::to($admin->email)->send(new TemplatedMail($this->record->key, static::sampleVars()));
                    Notification::make()
                        ->title(__('admin.email_template_test_sent', ['email' => $admin->email]))
                        ->success()
                        ->send();
                } catch (\Throwable $e) {
                    Notification::make()->title($e->getMessage())->danger()->send();
                }
            });
    }

    /** Reset subject/body back to the shipped default for this template type. */
    private function restoreAction(): Action
    {
        return Action::make('restore')
            ->label(__('admin.email_template_restore_default'))
            ->icon('heroicon-o-arrow-path')
            ->color('danger')
            ->requiresConfirmation()
            ->action(function () {
                $this->record->restoreDefaults();
                $this->fillForm();

                Notification::make()->title(__('admin.email_template_restored'))->success()->send();
            });
    }

    /** @return array<string,mixed> */
    private static function sampleVars(): array
    {
        return [
            'code'     => '123456',
            'app_name' => config('app.name'),
            'year'     => date('Y'),
        ];
    }
}
