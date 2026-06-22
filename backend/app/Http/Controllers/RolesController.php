<?php

namespace App\Http\Controllers;

use App\Http\Resources\RoleResource;
use App\Models\Role;
use App\Models\User;
use App\Support\PermissionCatalog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * RBAC management (ported from NestJS `roles.controller.ts` / `roles.service.ts`).
 * Routes mounted without the per-project prefix:
 *   GET    /permissions      catalog (manage_roles | manage_users)
 *   GET    /roles            list    (manage_roles | manage_users)
 *   POST   /roles            create  (manage_roles)
 *   PATCH  /roles/{id}       update  (manage_roles)
 *   DELETE /roles/{id}       delete  (manage_roles)
 */
class RolesController extends Controller
{
    /** GET /permissions — catalog of all assignable permissions. */
    public function permissions(): JsonResponse
    {
        return response()->ok(PermissionCatalog::all());
    }

    /** GET /roles — every role with its permission set. */
    public function index(): JsonResponse
    {
        $roles = Role::orderBy('sort_order')->orderBy('name')->get();

        return response()->ok(RoleResource::collection($roles));
    }

    /** POST /roles — create a custom (non-system) role. */
    public function store(Request $request): JsonResponse
    {
        $data = $this->validatePayload($request, required: true);
        $user = $request->user();

        $this->assertAssignable($data['permissions'] ?? [], $user);

        $key = $this->slugify($data['name']);
        if ($key === '') {
            throw new HttpException(400, 'Invalid role name');
        }
        if (Role::where('key', $key)->exists()) {
            throw new HttpException(409, 'A role with this name already exists');
        }

        $role = Role::create([
            'key' => $key,
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'is_system' => false,
            'permissions' => $data['permissions'] ?? [],
            'sort_order' => ((int) Role::max('sort_order')) + 1,
        ]);

        // `created_at` is filled by a DB default (model has no timestamps), so
        // reload to return the populated value the frontend expects.
        return response()->ok(new RoleResource($role->fresh()), 201);
    }

    /** PATCH /roles/{id} — rename / re-describe / re-permission a role. */
    public function update(Request $request, string $id): JsonResponse
    {
        $data = $this->validatePayload($request, required: false);
        $user = $request->user();
        $role = Role::findOrFail($id);

        $actorRoleKey = $user->assignedRole?->key;

        if ($role->key === 'owner' && $actorRoleKey !== 'owner') {
            throw new HttpException(400, 'Only an owner can modify the Owner role');
        }

        if (array_key_exists('permissions', $data)) {
            $this->assertAssignable($data['permissions'], $user);
            if ($user->role_id === $role->id && ! in_array('manage_roles', $data['permissions'], true)) {
                throw new HttpException(400, 'You cannot remove manage_roles from your own role');
            }
        }

        // System roles keep their identity (name/key); permissions stay editable.
        if ($role->is_system && array_key_exists('name', $data) && $data['name'] !== $role->name) {
            throw new HttpException(400, 'Cannot rename a system role');
        }

        if (array_key_exists('name', $data)) {
            $role->name = $data['name'];
        }
        if (array_key_exists('description', $data)) {
            $role->description = $data['description'];
        }
        if (array_key_exists('permissions', $data)) {
            $role->permissions = $data['permissions'];
        }
        $role->save();

        return response()->ok(new RoleResource($role));
    }

    /** DELETE /roles/{id} — remove a non-system role with no assigned users. */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $role = Role::findOrFail($id);

        if ($role->is_system) {
            throw new HttpException(400, 'Cannot delete a system role');
        }
        if ($user->role_id === $role->id) {
            throw new HttpException(400, 'You cannot delete your own role');
        }
        $assigned = User::where('role_id', $role->id)->count();
        if ($assigned > 0) {
            throw new HttpException(409, "Cannot delete a role assigned to {$assigned} user(s)");
        }

        $role->delete();

        return response()->ok(null);
    }

    /**
     * Validate the create/update body. On create `name` is required; on update
     * every field is optional (only provided keys are applied).
     *
     * @return array{name?:string,description?:string|null,permissions?:string[]}
     */
    private function validatePayload(Request $request, bool $required): array
    {
        return $request->validate([
            'name' => [$required ? 'required' : 'sometimes', 'string', 'min:2'],
            'description' => ['sometimes', 'nullable', 'string'],
            'permissions' => ['sometimes', 'array'],
            'permissions.*' => ['string', Rule::in(PermissionCatalog::keys())],
        ]);
    }

    /**
     * A non-owner actor may only grant permissions they themselves hold.
     */
    private function assertAssignable(array $requested, User $user): void
    {
        if ($user->assignedRole?->key === 'owner') {
            return;
        }
        $forbidden = array_values(array_diff($requested, $user->permissions()));
        if ($forbidden !== []) {
            throw ValidationException::withMessages([
                'permissions' => 'Cannot grant permission(s) you do not hold: '.implode(', ', $forbidden),
            ]);
        }
    }

    private function slugify(string $name): string
    {
        $slug = strtolower(trim($name));
        $slug = preg_replace('/[^a-z0-9\s-]/', '', $slug) ?? '';
        $slug = preg_replace('/\s+/', '-', $slug) ?? '';
        $slug = preg_replace('/-+/', '-', $slug) ?? '';

        return substr(trim($slug, '-'), 0, 50);
    }
}
