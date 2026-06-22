<?php

use App\Models\Project;
use App\Models\ProjectMember;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('project.{projectId}', fn ($user, string $projectId) => Project::whereKey($projectId)->where('owner_id', $user->id)->exists()
    || ProjectMember::where('project_id', $projectId)->where('user_id', $user->id)->exists()
    || $user->hasPermission('view_all_projects'));

Broadcast::channel('user.{id}', fn ($user, string $id) => $user->id === $id);
