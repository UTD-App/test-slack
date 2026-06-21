<?php

namespace App\Filament\Tables\Columns;

use App\Services\StorageConfigService;
use Closure;
use Filament\Tables\Columns\Column;
use Illuminate\Database\Eloquent\Model;
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

    /**
     * Optional link target for the cell (avatar + name become clickable).
     *
     * NB: this is deliberately SEPARATE from Filament's Column::url(). Setting the
     * column url makes Filament wrap the whole cell in an <a>, and this column's
     * view ALSO renders <a> tags — nested anchors are invalid HTML and the browser
     * tears the layout apart (cells bleed into each other). Using our own callback
     * keeps the single link inside the view. @var Closure|string|null
     */
    protected $profileUrlCallback = null;

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

    /** Make the cell link to the user's profile. Closure receives the row `$record`. */
    public function profileUrl(Closure|string|null $url): static
    {
        $this->profileUrlCallback = $url;

        return $this;
    }

    /** Resolve the profile link for the current row (null = render no link). */
    public function getProfileUrl(): ?string
    {
        if ($this->profileUrlCallback === null) {
            return null;
        }

        $url = $this->evaluate($this->profileUrlCallback, ['record' => $this->getRecord()]);

        return filled($url) ? $url : null;
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

    /** A real avatar (resolved for the admin browser) or the bundled default image. */
    public function getAvatarUrl(): string
    {
        $avatar = $this->getUser()?->avatar;

        if (is_string($avatar) && $avatar !== '') {
            // Driver-aware resolution shared with the profile page: absolute cloud
            // URL for GCS/S3, host-relative /storage/… for the local public disk
            // (whose configured host may be the emulator's 10.0.2.2), passthrough
            // for external URLs. See StorageConfigService::webUrl().
            $url = app(StorageConfigService::class)->webUrl($avatar);
            if (filled($url)) {
                return $url;
            }
        }

        return self::defaultAvatarUrl();
    }

    /** Bundled local default avatar (shown when a user has no picture). */
    public static function defaultAvatarUrl(): string
    {
        return asset('images/default-avatar.svg');
    }

    public function getCopyMessage(): string
    {
        return __('admin.copied');
    }
}
