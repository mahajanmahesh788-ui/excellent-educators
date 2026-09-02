<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('aptitude_assessments', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('career_compass_level_id')->constrained('career_compass_levels')->restrictOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status')->default('draft');
            $table->foreignUlid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUlid('updated_by')->nullable()->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('aptitude_assessment_questions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('aptitude_assessment_id')->constrained('aptitude_assessments')->restrictOnDelete();
            $table->text('question_text');
            $table->unsignedSmallInteger('display_order')->default(1);
            $table->timestamps();
        });

        Schema::create('aptitude_assessment_options', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('aptitude_assessment_question_id')->constrained('aptitude_assessment_questions')->restrictOnDelete();
            $table->string('option_text');
            $table->string('dimension_code', 8);
            $table->unsignedSmallInteger('display_order')->default(1);
            $table->timestamps();
        });

        Schema::create('aptitude_assessment_attempts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('aptitude_assessment_id')->constrained('aptitude_assessments')->restrictOnDelete();
            $table->foreignUlid('student_id')->constrained('student_profiles')->restrictOnDelete();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('submitted_at')->nullable();
            $table->string('status')->default('started');
            $table->timestamps();
        });

        Schema::create('aptitude_assessment_answers', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('aptitude_assessment_attempt_id')->constrained('aptitude_assessment_attempts')->restrictOnDelete();
            $table->foreignUlid('aptitude_assessment_question_id')->constrained('aptitude_assessment_questions')->restrictOnDelete();
            $table->foreignUlid('aptitude_assessment_option_id')->constrained('aptitude_assessment_options')->restrictOnDelete();
            $table->timestamps();
            $table->unique(['aptitude_assessment_attempt_id', 'aptitude_assessment_question_id'], 'aptitude_answers_attempt_question_unique');
        });

        Schema::create('aptitude_assessment_results', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('aptitude_assessment_attempt_id')->unique()->constrained('aptitude_assessment_attempts')->restrictOnDelete();
            $table->foreignUlid('student_id')->constrained('student_profiles')->restrictOnDelete();
            $table->timestamp('calculated_at');
            $table->timestamps();
        });

        Schema::create('aptitude_assessment_result_dimensions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('aptitude_assessment_result_id')->constrained('aptitude_assessment_results')->restrictOnDelete();
            $table->string('dimension_code', 8);
            $table->unsignedInteger('score')->default(0);
            $table->timestamps();
            $table->unique(['aptitude_assessment_result_id', 'dimension_code'], 'aptitude_result_dimension_unique');
        });

        DB::statement("CREATE UNIQUE INDEX aptitude_attempts_one_submitted_per_student ON aptitude_assessment_attempts (aptitude_assessment_id, student_id) WHERE status = 'submitted'");

        $codes = "'P','I','CF','L','CM','DM','CR','CU','TW','FA'";

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE aptitude_assessment_options ADD CONSTRAINT aptitude_options_dimension_code_check CHECK (dimension_code IN ({$codes}))");
            DB::statement("ALTER TABLE aptitude_assessment_result_dimensions ADD CONSTRAINT aptitude_result_dimension_code_check CHECK (dimension_code IN ({$codes}))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('aptitude_assessment_result_dimensions');
        Schema::dropIfExists('aptitude_assessment_results');
        Schema::dropIfExists('aptitude_assessment_answers');
        Schema::dropIfExists('aptitude_assessment_attempts');
        Schema::dropIfExists('aptitude_assessment_options');
        Schema::dropIfExists('aptitude_assessment_questions');
        Schema::dropIfExists('aptitude_assessments');
    }
};
