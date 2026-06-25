<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $isSqlite = Schema::getConnection()->getDriverName() === 'sqlite';

        Schema::table('tasks', function (Blueprint $table) {
            // QA assignee = the tester responsible for verifying the task.
            $table->uuid('qa_assignee_id')->nullable()->after('assignee_id');
            // Separate time bucket so testers log/estimate QA time independently.
            $table->decimal('qa_estimated_hours', 6, 2)->nullable()->after('estimated_hours');
            $table->decimal('qa_logged_hours', 6, 2)->default(0)->after('logged_hours');
        });

        // SQLite (test env) can't add FK constraints/indexes via ALTER — skip there.
        if (! $isSqlite) {
            Schema::table('tasks', function (Blueprint $table) {
                $table->foreign('qa_assignee_id')->references('id')->on('users')->nullOnDelete();
                $table->index('qa_assignee_id');
            });
        }

        Schema::table('working_hours', function (Blueprint $table) {
            // Distinguishes QA work logs from dev work logs.
            $table->boolean('is_qa')->default(false)->after('hours');
        });
    }

    public function down(): void
    {
        $isSqlite = Schema::getConnection()->getDriverName() === 'sqlite';

        Schema::table('tasks', function (Blueprint $table) use ($isSqlite) {
            if (! $isSqlite) {
                $table->dropForeign(['qa_assignee_id']);
                $table->dropIndex(['qa_assignee_id']);
            }
            $table->dropColumn(['qa_assignee_id', 'qa_estimated_hours', 'qa_logged_hours']);
        });

        Schema::table('working_hours', function (Blueprint $table) {
            $table->dropColumn('is_qa');
        });
    }
};
