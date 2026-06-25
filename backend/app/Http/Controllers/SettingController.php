<?php

namespace App\Http\Controllers;

use App\Models\AppSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Site-wide settings shared by all users (e.g. the display timezone used across
 * the web UI and exports). Reading is open to any authenticated user (the FE
 * needs the timezone to render dates); writing requires `manage_settings`.
 */
class SettingController extends Controller
{
    private const DEFAULT_TZ = 'Asia/Ho_Chi_Minh';

    /** GET /settings */
    public function index(): JsonResponse
    {
        return response()->ok($this->payload());
    }

    /** PUT /settings — requires manage_settings */
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'timezone' => ['required', 'string', Rule::in(timezone_identifiers_list())],
        ]);

        AppSetting::put('timezone', $data['timezone']);

        return response()->ok($this->payload());
    }

    private function payload(): array
    {
        return [
            'timezone' => AppSetting::get('timezone', self::DEFAULT_TZ),
        ];
    }
}
