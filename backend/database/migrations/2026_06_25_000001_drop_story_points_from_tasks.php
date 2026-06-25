<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('tasks', 'story_points')) {
            Schema::table('tasks', function (Blueprint $table) {
                $table->dropColumn('story_points');
            });
        }
    }

    public function down(): void
    {
        if (! Schema::hasColumn('tasks', 'story_points')) {
            Schema::table('tasks', function (Blueprint $table) {
                $table->integer('story_points')->nullable();
            });
        }
    }
};
