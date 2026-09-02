<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('actor_id')->nullable()->constrained('users')->restrictOnDelete();
            $table->string('actor_role')->nullable();
            $table->string('action');
            $table->string('subject_type');
            $table->ulid('subject_id');
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('request_id')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['subject_type', 'subject_id']);
            $table->index('actor_id');
            $table->index('action');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};
