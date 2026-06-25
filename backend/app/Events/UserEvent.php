<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserEvent implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    /** @var string[] */
    public array $userIds;

    /** @param string|string[] $userIds */
    public function __construct(array|string $userIds, public string $eventName, public array $payload = [])
    {
        $this->userIds = array_values(array_unique(array_filter((array) $userIds)));
    }

    public function broadcastOn(): array
    {
        return array_map(fn (string $id) => new PrivateChannel('user.'.$id), $this->userIds);
    }

    public function broadcastAs(): string
    {
        return $this->eventName;
    }

    public function broadcastWith(): array
    {
        return $this->payload;
    }
}
