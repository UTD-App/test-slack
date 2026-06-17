<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditUser extends EditRecord
{
    protected static string $resource = UserResource::class;

    /** Stashed between save and afterSave — avatar lives on the profile relation. */
    protected ?string $avatarPath = null;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }

    // Avatar is NOT a real user column (it's on the profile relation, shadowed by
    // an accessor) — load it explicitly so the uploader shows the current photo.
    protected function mutateFormDataBeforeFill(array $data): array
    {
        $data['avatar'] = $this->record->profile?->avatar;

        return $data;
    }

    // Pull avatar out so it isn't written to the shadowed users.avatar column.
    protected function mutateFormDataBeforeSave(array $data): array
    {
        $this->avatarPath = $data['avatar'] ?? null;
        unset($data['avatar']);

        return $data;
    }

    // Persist it to the profile relation — same write path as the API.
    protected function afterSave(): void
    {
        $this->record->profile()->updateOrCreate(
            ['user_id' => $this->record->id],
            ['avatar' => $this->avatarPath],
        );
    }
}
