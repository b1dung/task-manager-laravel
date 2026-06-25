<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Requesters are a label-like entity: free-form, colored chips created on
        // the fly to record who requested a task. Independent from `labels`.
        Schema::create('requesters', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('project_id')->constrained('projects')->cascadeOnDelete();
            $table->string('name');
            $table->string('color');
        });

        Schema::create('task_requesters', function (Blueprint $table) {
            $table->foreignUuid('task_id')->constrained('tasks')->cascadeOnDelete();
            $table->foreignUuid('requester_id')->constrained('requesters')->cascadeOnDelete();
            $table->primary(['task_id', 'requester_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('task_requesters');
        Schema::dropIfExists('requesters');
    }
};
