<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ProjectEvent implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(public string $projectId, public string $eventName, public array $payload) {}

    /**
     * Realtime is a best-effort side-effect: a broadcaster that is unreachable or
     * misconfigured (e.g. Pusher/Reverb on the shared-hosting dev site) must NEVER
     * fail the HTTP request that triggered it. Because this event is ShouldBroadcastNow
     * it broadcasts synchronously inside dispatch(), so we wrap it and only log on
     * failure. Overrides the Dispatchable trait's dispatch() — every call site keeps
     * using ProjectEvent::dispatch(...) unchanged.
     */
    public static function dispatch(...$arguments): void
    {
        try {
            event(new static(...$arguments));
        } catch (\Throwable $e) {
            report($e);
        }
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel('project.'.$this->projectId)];
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
