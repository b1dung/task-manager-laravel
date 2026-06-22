<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('projects', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->foreignUuid('owner_id')->constrained('users')->cascadeOnDelete();
            $table->json('settings_json')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestampTz('deadline')->nullable();
            $table->timestampTz('archived_at')->nullable();
            $table->uuid('archived_by')->nullable();
            $table->softDeletes(); // deleted_at
        });

        Schema::create('project_members', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('project_id')->constrained('projects')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('role', ['admin', 'manager', 'member', 'viewer'])->default('member');
            $table->timestamp('joined_at')->useCurrent();
            $table->unique(['project_id', 'user_id']);
        });

        // One row per project: last issued task number (for {KEY}-{n} ids).
        Schema::create('project_task_counters', function (Blueprint $table) {
            $table->foreignUuid('project_id')->primary()->constrained('projects')->cascadeOnDelete();
            $table->integer('last_number')->default(0);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('project_task_counters');
        Schema::dropIfExists('project_members');
        Schema::dropIfExists('projects');
    }
};
