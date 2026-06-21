<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use Filament\Resources\Pages\CreateRecord;

class CreateUser extends CreateRecord
{
    protected static string $resource = UserResource::class;

    /** Stashed between create and afterCreate — avatar lives on the profile relation. */
    protected ?string $avatarPath = null;

    /** Stashed between create and afterCreate — covers live on the profile relation. */
    protected array $coversPaths = [];

    // Pull avatar/covers out so they aren't written to user columns — they live
    // on the profile relation.
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $this->avatarPath = $data['avatar'] ?? null;
        $this->coversPaths = array_values($data['covers'] ?? []);
        unset($data['avatar'], $data['covers']);

        return $data;
    }

    // Persist them to the profile relation — same write path as the API.
    protected function afterCreate(): void
    {
        if (filled($this->avatarPath) || ! empty($this->coversPaths)) {
            $this->record->profile()->updateOrCreate(
                ['user_id' => $this->record->id],
                ['avatar' => $this->avatarPath, 'covers' => $this->coversPaths],
            );
        }
    }
}
