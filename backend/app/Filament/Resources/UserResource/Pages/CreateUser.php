<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use Filament\Resources\Pages\CreateRecord;

class CreateUser extends CreateRecord
{
    protected static string $resource = UserResource::class;

    /** Stashed between create and afterCreate — avatar lives on the profile relation. */
    protected ?string $avatarPath = null;

    // Pull avatar out so it isn't written to the shadowed users.avatar column.
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $this->avatarPath = $data['avatar'] ?? null;
        unset($data['avatar']);

        return $data;
    }

    // Persist it to the profile relation — same write path as the API.
    protected function afterCreate(): void
    {
        if (filled($this->avatarPath)) {
            $this->record->profile()->updateOrCreate(
                ['user_id' => $this->record->id],
                ['avatar' => $this->avatarPath],
            );
        }
    }
}
