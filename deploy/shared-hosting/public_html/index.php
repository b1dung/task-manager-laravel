<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

// Shared-hosting layout: docroot = public_html/, Laravel app = ../laravel/
define('LARAVEL_START', microtime(true));

// Maintenance mode...
if (file_exists($maintenance = __DIR__.'/../laravel/storage/framework/maintenance.php')) {
    require $maintenance;
}

// Composer autoloader...
require __DIR__.'/../laravel/vendor/autoload.php';

// Bootstrap Laravel and handle the request...
/** @var Application $app */
$app = require_once __DIR__.'/../laravel/bootstrap/app.php';

$app->handleRequest(Request::capture());
