<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assessments', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('batch_id')->constrained('batches')->restrictOnDelete();
            $table->foreignUlid('created_by')->constrained('users')->restrictOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->decimal('max_score', 6, 2);
            $table->unsignedSmallInteger('version')->default(1);
            $table->string('status')->default('draft');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('assessment_versions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('assessment_id')->constrained('assessments')->restrictOnDelete();
            $table->unsignedSmallInteger('version');
            $table->string('title');
            $table->text('description')->nullable();
            $table->decimal('max_score', 6, 2);
            $table->foreignUlid('revised_by')->constrained('users')->restrictOnDelete();
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['assessment_id', 'version']);
        });

        Schema::create('assessment_scores', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('assessment_id')->constrained('assessments')->restrictOnDelete();
            $table->foreignUlid('student_id')->constrained('student_profiles')->restrictOnDelete();
            $table->unsignedSmallInteger('version');
            $table->decimal('score', 6, 2)->nullable();
            $table->string('notes')->nullable();
            $table->foreignUlid('scored_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamp('scored_at')->nullable();
            $table->timestamps();
            $table->unique(['assessment_id', 'student_id', 'version']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assessment_scores');
        Schema::dropIfExists('assessment_versions');
        Schema::dropIfExists('assessments');
    }
};
