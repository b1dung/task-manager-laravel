<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BoardFlowTest extends TestCase
{
    use RefreshDatabase;

    private function actingAdmin(): User
    {
        $role = Role::create([
            'key' => 'admin', 'name' => 'Admin', 'is_system' => true, 'sort_order' => 1,
            'permissions' => ['create_project', 'view_all_projects'],
        ]);
        $user = User::create([
            'email' => 'a@taskboard.dev', 'password_hash' => bcrypt('x'),
            'full_name' => 'Admin', 'role' => 'admin', 'role_id' => $role->id, 'is_active' => true,
        ]);
        Sanctum::actingAs($user);

        return $user;
    }

    public function test_create_project_seeds_default_columns(): void
    {
        $this->actingAdmin();

        $res = $this->postJson('/api/v1/projects', ['name' => 'Demo'])
            ->assertCreated()
            ->assertJsonPath('success', true);
        $pid = $res->json('data.id');

        $this->getJson("/api/v1/projects/{$pid}/columns")
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('data.0.name', 'To Do');
    }

    public function test_moving_task_to_done_column_sets_status_done(): void
    {
        $this->actingAdmin();
        $pid = $this->postJson('/api/v1/projects', ['name' => 'Demo'])->json('data.id');
        $cols = $this->getJson("/api/v1/projects/{$pid}/columns")->json('data');
        $todo = $cols[0]['id'];
        $done = collect($cols)->firstWhere('name', 'Done')['id'];

        $tid = $this->postJson("/api/v1/projects/{$pid}/tasks", ['columnId' => $todo, 'title' => 'T1'])
            ->assertJsonPath('data.status', 'todo')
            ->assertJsonPath('data.taskNumber', 1)
            ->json('data.id');

        $this->patchJson("/api/v1/projects/{$pid}/tasks/{$tid}/move", ['columnId' => $done, 'position' => 0])
            ->assertJsonPath('data.status', 'done')
            ->assertJsonPath('data.columnId', $done);
    }

    public function test_member_cannot_create_project(): void
    {
        $role = Role::create(['key' => 'member', 'name' => 'Member', 'is_system' => true, 'sort_order' => 4, 'permissions' => ['create_task']]);
        $user = User::create(['email' => 'm@taskboard.dev', 'password_hash' => bcrypt('x'), 'full_name' => 'M', 'role' => 'member', 'role_id' => $role->id, 'is_active' => true]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/projects', ['name' => 'Nope'])->assertForbidden();
    }
}
