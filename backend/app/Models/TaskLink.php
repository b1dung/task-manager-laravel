<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TaskLink extends Model
{
    use HasUuids;

    protected $keyType = 'string';

    public $incrementing = false;

    public $timestamps = false;

    protected $guarded = [];

    public function source(): BelongsTo
    {
        return $this->belongsTo(Task::class, 'source_task_id');
    }

    public function target(): BelongsTo
    {
        return $this->belongsTo(Task::class, 'target_task_id');
    }
}
