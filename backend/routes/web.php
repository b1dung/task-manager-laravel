<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::get('/uploads/avatars/{filename}', function (string $filename) {
    abort_if(str_contains($filename, '..') || ! Storage::disk('public')->exists('avatars/'.$filename), 404);

    return Storage::disk('public')->response('avatars/'.$filename);
})->where('filename', '[A-Za-z0-9._-]+');

Route::get('/', function () {
    return view('welcome');
});
