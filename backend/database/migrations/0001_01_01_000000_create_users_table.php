<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Mirrors the existing NestJS `users` table (no updated_at by design).
        Schema::create('users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('email')->unique();
            $table->string('password_hash');
            $table->string('full_name');
            $table->string('avatar_url')->nullable();
            $table->enum('role', ['admin', 'manager', 'member', 'viewer'])->default('member');
            $table->boolean('is_active')->default(true);
            $table->uuid('role_id')->nullable()->index(); // FK -> roles added later
            $table->string('language', 5)->default('en');
            $table->string('appearance', 16)->default('light');
            $table->string('timezone', 64)->default('Asia/Ho_Chi_Minh');
            $table->timestampTz('email_verified_at')->nullable();
            $table->boolean('two_factor_enabled')->default(false);
            // Laravel's encrypted payload is larger than VARCHAR(255).
            $table->text('two_factor_secret')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        // Laravel session store (SESSION_DRIVER=database). user_id is a UUID here.
        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->uuid('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('users');
    }
};
