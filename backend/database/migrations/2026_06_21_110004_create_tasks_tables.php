<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('project_id')->constrained('projects')->cascadeOnDelete();
            $table->foreignUuid('column_id')->constrained('columns')->cascadeOnDelete();
            $table->foreignUuid('sprint_id')->nullable()->constrained('sprints')->nullOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('type', ['bug', 'feature', 'task', 'story', 'epic'])->default('task');
            $table->enum('priority', ['urgent', 'high', 'medium', 'low', 'lowest'])->default('medium');
            $table->enum('status', ['todo', 'in_progress', 'in_review', 'done'])->default('todo');
            $table->foreignUuid('assignee_id')->nullable()->constrained('users')->nullOnDelete();
            // reporter_id is nullable so the SET NULL on user delete is valid in MySQL.
            $table->foreignUuid('reporter_id')->nullable()->constrained('users')->nullOnDelete();
            $table->date('due_date')->nullable();
            $table->decimal('estimated_hours', 6, 2)->nullable();
            $table->decimal('logged_hours', 6, 2)->default(0);
            $table->integer('story_points')->nullable();
            $table->integer('position')->default(0);
            $table->foreignUuid('parent_task_id')->nullable()->constrained('tasks')->cascadeOnDelete();
            $table->integer('task_number')->nullable();
            $table->timestampTz('archived_at')->nullable();
            $table->uuid('archived_by')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
            $table->softDeletes(); // deleted_at

            $table->index(['project_id', 'status']);
            $table->index(['column_id', 'position']);
            $table->index(['project_id', 'created_at']);
            $table->index('due_date');
            // {KEY}-{n} uniqueness per project.
            $table->unique(['project_id', 'task_number']);
            // Full-text search (replaces Postgres pg_trgm gin indexes).
            // SQLite (test env) has no fulltext — skip there; MySQL/Pgsql get it.
            if (Schema::getConnection()->getDriverName() !== 'sqlite') {
                $table->fullText(['title', 'description']);
            }
        });

        Schema::create('task_links', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('source_task_id')->constrained('tasks')->cascadeOnDelete();
            $table->foreignUuid('target_task_id')->constrained('tasks')->cascadeOnDelete();
            $table->enum('link_type', ['blocks', 'blocked_by', 'relates_to']);
        });

        Schema::create('task_labels', function (Blueprint $table) {
            $table->foreignUuid('task_id')->constrained('tasks')->cascadeOnDelete();
            $table->foreignUuid('label_id')->constrained('labels')->cascadeOnDelete();
            $table->primary(['task_id', 'label_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('task_labels');
        Schema::dropIfExists('task_links');
        Schema::dropIfExists('tasks');
    }
};
