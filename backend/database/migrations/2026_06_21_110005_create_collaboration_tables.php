<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('comments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('task_id')->constrained('tasks')->cascadeOnDelete();
            $table->foreignUuid('author_id')->constrained('users')->cascadeOnDelete();
            $table->text('content');
            $table->foreignUuid('parent_id')->nullable()->constrained('comments')->cascadeOnDelete();
            $table->timestampTz('edited_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->softDeletes(); // deleted_at
        });

        Schema::create('comment_mentions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('comment_id')->constrained('comments')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
        });

        Schema::create('attachments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('task_id')->constrained('tasks')->cascadeOnDelete();
            // uploader_id nullable so SET NULL on user delete is valid in MySQL.
            $table->foreignUuid('uploader_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('file_name');
            $table->string('file_url');
            $table->unsignedBigInteger('file_size');
            $table->string('mime_type');
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('working_hours', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('task_id')->constrained('tasks')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('hours', 6, 2);
            $table->date('logged_date');
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('working_hours');
        Schema::dropIfExists('attachments');
        Schema::dropIfExists('comment_mentions');
        Schema::dropIfExists('comments');
    }
};
