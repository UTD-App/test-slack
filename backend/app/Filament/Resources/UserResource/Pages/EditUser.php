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

    /** Stashed between save and afterSave — covers live on the profile relation. */
    protected array $coversPaths = [];

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
        $data['covers'] = $this->record->profile?->covers ?? [];

        return $data;
    }

    // Pull avatar/covers out so they aren't written to user columns — they live
    // on the profile relation.
    protected function mutateFormDataBeforeSave(array $data): array
    {
        $this->avatarPath = $data['avatar'] ?? null;
        $this->coversPaths = array_values($data['covers'] ?? []);
        unset($data['avatar'], $data['covers']);

        return $data;
    }

    // Persist them to the profile relation — same write path as the API.
    protected function afterSave(): void
    {
        $this->record->profile()->updateOrCreate(
            ['user_id' => $this->record->id],
            ['avatar' => $this->avatarPath, 'covers' => $this->coversPaths],
        );
    }
}
