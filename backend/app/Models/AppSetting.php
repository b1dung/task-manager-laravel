<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Site-wide key/value settings. Use the get()/put() helpers rather than the
 * model directly for the common single-key read/write.
 */
class AppSetting extends Model
{
    protected $primaryKey = 'key';

    protected $keyType = 'string';

    public $incrementing = false;

    public $timestamps = false;

    protected $guarded = [];

    public static function get(string $key, ?string $default = null): ?string
    {
        return static::query()->whereKey($key)->value('value') ?? $default;
    }

    public static function put(string $key, ?string $value): void
    {
        static::query()->updateOrCreate(['key' => $key], ['value' => $value]);
    }
}
