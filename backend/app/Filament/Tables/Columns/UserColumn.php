<?php

namespace App\Filament\Tables\Columns;

use Filament\Tables\Columns\Column;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Reusable "user cell" for any admin table: avatar + name + a copyable UID.
 *
 * Drop into any resource table's columns():
 *   UserColumn::make()                       // the row record IS the user
 *   UserColumn::make('sender')               // a `sender` relationship on the row
 *   UserColumn::make('receiver')->label(__('gifts::admin.receiver'))
 *
 * Eager-load the relation (+ its `profile`, which backs the avatar accessor):
 *   ->modifyQueryUsing(fn ($q) => $q->with(['sender.profile', 'receiver.profile']))
 */
class UserColumn extends Column
{
    protected string $view = 'filament.tables.columns.user-column';

    /** '' = the row record itself; otherwise a relationship name like 'sender'. */
    protected string $userRelationship = '';

    /** Attribute shown/copied as the UID (the distinctive `uuid` by default). */
    protected string $uidAttribute = 'uuid';

    public static function make(?string $name = null): static
    {
        $relationship = $name ?? '';

        // Column needs a unique key; reuse the relationship name, else "user".
        $column = parent::make($relationship !== '' ? $relationship : 'user');
        $column->userRelationship = $relationship;

        return $column;
    }

    public function uidAttribute(string $attribute): static
    {
        $this->uidAttribute = $attribute;

        return $this;
    }

    /** Resolve the User model this cell represents (record itself, or a relation). */
    public function getUser(): ?Model
    {
        $record = $this->getRecord();

        if ($this->userRelationship === '') {
            return $record instanceof Model ? $record : null;
        }

        $user = data_get($record, $this->userRelationship);

        return $user instanceof Model ? $user : null;
    }

    public function getDisplayName(): string
    {
        return (string) ($this->getUser()?->name ?: '—');
    }

    /** The full UID — what gets copied to the clipboard. */
    public function getUid(): string
    {
        return (string) ($this->getUser()?->{$this->uidAttribute} ?? '');
    }

    /** A shortened UID for display (the full value is still copied). */
    public function getUidDisplay(): string
    {
        return Str::limit($this->getUid(), 12, '…');
    }

    /** A real avatar (absolute URL or public-disk path) or a name-based placeholder. */
    public function getAvatarUrl(): string
    {
        $user = $this->getUser();
        $avatar = $user?->avatar;

        if (is_string($avatar) && $avatar !== '') {
            return Str::startsWith($avatar, ['http://', 'https://'])
                ? $avatar
                : Storage::disk('public')->url($avatar);
        }

        return 'https://ui-avatars.com/api/?background=random&name=' . urlencode($user?->name ?: 'U');
    }

    public function getCopyMessage(): string
    {
        return __('admin.copied');
    }
}
