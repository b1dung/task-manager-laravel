<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Task extends Model
{
    use HasUuids, SoftDeletes;

    protected $keyType = 'string';

    public $incrementing = false;

    public $timestamps = true; // created_at + updated_at

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'due_date' => 'date',
            'estimated_hours' => 'decimal:2',
            'logged_hours' => 'decimal:2',
            'archived_at' => 'datetime',
        ];
    }

    /**
     * Columns are the source of truth for "status"; the enum is derived from the
     * column name. Ported from NestJS tasks.service.ts columnNameToStatus().
     */
    public static function columnNameToStatus(?string $name): string
    {
        $n = strtolower($name ?? '');

        return match (true) {
            str_contains($n, 'done') || str_contains($n, 'complete') || str_contains($n, 'closed') => 'done',
            str_contains($n, 'review') || str_contains($n, 'testing') || str_contains($n, 'qa') => 'in_review',
            str_contains($n, 'progress') || str_contains($n, 'doing') || str_contains($n, 'active') || str_contains($n, 'wip') => 'in_progress',
            default => 'todo',
        };
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    public function column(): BelongsTo
    {
        return $this->belongsTo(Column::class);
    }

    public function sprint(): BelongsTo
    {
        return $this->belongsTo(Sprint::class);
    }

    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assignee_id');
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(Task::class, 'parent_task_id');
    }

    public function subtasks(): HasMany
    {
        return $this->hasMany(Task::class, 'parent_task_id');
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(Attachment::class);
    }

    public function labels(): BelongsToMany
    {
        return $this->belongsToMany(Label::class, 'task_labels');
    }
}
