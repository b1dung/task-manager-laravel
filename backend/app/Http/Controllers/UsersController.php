<?php

namespace App\Http\Controllers;

use App\Http\Resources\AppUserResource;
use App\Models\Task;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class UsersController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = User::query()->with('assignedRole')->orderBy('created_at', 'desc');
        if ($q = trim((string) $request->query('q', ''))) {
            $query->where(fn ($sub) => $sub->where('full_name', 'like', "%{$q}%")->orWhere('email', 'like', "%{$q}%"));
        }

        return response()->ok(AppUserResource::collection($query->get()));
    }

    public function show(string $id): JsonResponse
    {
        return response()->ok(new AppUserResource(User::findOrFail($id)));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'fullName' => ['required', 'string', 'min:2'],
            'role' => ['nullable', 'in:admin,manager,member,viewer'],
            'roleId' => ['nullable', 'uuid'],
        ]);

        $user = User::create([
            'email' => $data['email'],
            'password_hash' => Hash::make($data['password']),
            'full_name' => $data['fullName'],
            'role' => $data['role'] ?? 'member',
            'role_id' => $data['roleId'] ?? null,
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        return response()->ok(new AppUserResource($user->fresh()), 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'fullName' => ['nullable', 'string', 'min:2'],
            'email' => ['nullable', 'email'],
            'role' => ['nullable', 'in:admin,manager,member,viewer'],
            'roleId' => ['nullable', 'uuid'],
            'isActive' => ['nullable', 'boolean'],
            'language' => ['nullable', 'in:en,vi,ja'],
            'appearance' => ['nullable', 'in:light,midnight,mint'],
        ]);

        $user = User::findOrFail($id);
        $this->authorizeEdit($request, $user);

        foreach ([
            'fullName' => 'full_name', 'email' => 'email', 'language' => 'language',
            'appearance' => 'appearance',
        ] as $in => $col) {
            if ($request->has($in)) {
                $user->{$col} = $data[$in];
            }
        }
        // Admin-only fields.
        if ($request->user()->hasPermission('manage_users')) {
            if ($request->has('role')) {
                $user->role = $data['role'];
            }
            if ($request->has('roleId')) {
                $user->role_id = $data['roleId'];
            }
            if ($request->has('isActive')) {
                $user->is_active = $data['isActive'];
            }
        }
        $user->save();

        return response()->ok(new AppUserResource($user));
    }

    public function destroy(string $id): JsonResponse
    {
        User::findOrFail($id)->delete();

        return response()->ok(null);
    }

    public function changePassword(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'currentPassword' => ['required', 'string'],
            'newPassword' => ['required', 'string', 'min:8'],
        ]);

        $user = User::findOrFail($id);
        abort_unless($user->id === $request->user()->id, 403, 'You can only change your own password');
        if (! Hash::check($data['currentPassword'], $user->password_hash)) {
            throw ValidationException::withMessages(['currentPassword' => 'Current password is incorrect']);
        }

        $user->update(['password_hash' => Hash::make($data['newPassword'])]);

        return response()->ok(null);
    }

    public function uploadAvatar(Request $request, string $id): JsonResponse
    {
        $request->validate(['file' => ['required', 'image', 'max:'.(2 * 1024)]]); // 2 MB

        $user = User::findOrFail($id);
        $this->authorizeEdit($request, $user);

        $file = $request->file('file');
        $stored = Str::uuid().'.'.$file->getClientOriginalExtension();
        Storage::disk('public')->putFileAs('avatars', $file, $stored);
        $user->update(['avatar_url' => '/uploads/avatars/'.$stored]);

        return response()->ok(new AppUserResource($user));
    }

    public function exportOwnData(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->ok([
            'user' => new AppUserResource($user),
            'ownedProjects' => $user->ownedProjects()->get(['id', 'name', 'slug']),
            'assignedTasks' => Task::where('assignee_id', $user->id)->get(['id', 'title', 'status', 'project_id']),
        ]);
    }

    public function deleteOwnAccount(Request $request): JsonResponse
    {
        $data = $request->validate(['currentPassword' => ['required', 'string']]);
        $user = $request->user();
        if (! Hash::check($data['currentPassword'], $user->password_hash)) {
            throw ValidationException::withMessages(['currentPassword' => 'Current password is incorrect']);
        }
        $user->delete();

        return response()->ok(null);
    }

    private function authorizeEdit(Request $request, User $user): void
    {
        abort_unless(
            $user->id === $request->user()->id || $request->user()->hasPermission('manage_users'),
            403,
            'Not allowed',
        );
    }
}
