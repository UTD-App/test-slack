<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\Notifications\NotificationManager;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Heavy fan-out for {@see NotificationManager::broadcast()} — sends one
 * notification type to every user (or a list of ids) in chunks, off the request
 * cycle. Each user is rendered in their own locale by the manager. Runs on the
 * default queue; point a dedicated worker at it for large broadcasts.
 */
class SendNotificationJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    /**
     * @param  array<string,mixed>   $params
     * @param  array<string,mixed>   $data
     * @param  array<int,int>|null   $userIds  null = every user
     */
    public function __construct(
        public string $typeKey,
        public array $params = [],
        public array $data = [],
        public ?array $userIds = null,
        public int $chunkSize = 500,
    ) {
    }

    public function handle(NotificationManager $notifier): void
    {
        $query = User::query();

        if ($this->userIds !== null) {
            $query->whereIn('id', $this->userIds);
        }

        $query->chunkById($this->chunkSize, function ($users) use ($notifier) {
            foreach ($users as $user) {
                $notifier->send($user, $this->typeKey, $this->params, $this->data);
            }
        });
    }
}
