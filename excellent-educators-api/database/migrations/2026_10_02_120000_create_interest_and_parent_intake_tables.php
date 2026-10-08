<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('interest_questions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->text('question_text');
            $table->boolean('allow_other')->default(true);
            $table->unsignedTinyInteger('max_selections')->default(5);
            $table->unsignedInteger('display_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('interest_options', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('interest_question_id')->constrained('interest_questions')->cascadeOnDelete();
            $table->string('option_text', 100);
            $table->string('normalized_key', 120);
            $table->string('source', 20)->default('admin');
            $table->unsignedInteger('display_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('usage_count')->default(0);
            $table->timestamps();
            $table->unique(['interest_question_id', 'normalized_key'], 'interest_options_question_key_unique');
        });

        Schema::create('interest_responses', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->timestamp('completed_at');
            $table->timestamps();
            $table->unique('student_id');
        });

        Schema::create('interest_response_answers', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('interest_response_id')->constrained('interest_responses')->cascadeOnDelete();
            $table->foreignUlid('interest_question_id')->constrained('interest_questions')->cascadeOnDelete();
            $table->string('other_text', 25)->nullable();
            $table->timestamps();
            $table->unique(['interest_response_id', 'interest_question_id'], 'interest_answer_unique');
        });

        Schema::create('interest_response_answer_options', function (Blueprint $table) {
            $table->foreignUlid('interest_response_answer_id')
                ->constrained('interest_response_answers', 'id', 'irao_answer_fk')
                ->cascadeOnDelete();
            $table->foreignUlid('interest_option_id')
                ->constrained('interest_options', 'id', 'irao_option_fk')
                ->cascadeOnDelete();
            $table->timestamps();
            $table->primary(
                ['interest_response_answer_id', 'interest_option_id'],
                'irao_primary',
            );
        });

        Schema::create('parent_questions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->text('question_text');
            $table->string('question_type', 20)->default('text');
            $table->unsignedInteger('display_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('parent_options', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('parent_question_id')->constrained('parent_questions')->cascadeOnDelete();
            $table->string('option_text', 255);
            $table->unsignedInteger('display_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('parent_responses', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('skipped_at')->nullable();
            $table->timestamps();
            $table->unique('student_id');
        });

        Schema::create('parent_response_answers', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('parent_response_id')->constrained('parent_responses')->cascadeOnDelete();
            $table->foreignUlid('parent_question_id')->constrained('parent_questions')->cascadeOnDelete();
            $table->text('text_answer')->nullable();
            $table->foreignUlid('parent_option_id')->nullable()->constrained('parent_options')->nullOnDelete();
            $table->timestamps();
            $table->unique(['parent_response_id', 'parent_question_id'], 'parent_answer_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('parent_response_answers');
        Schema::dropIfExists('parent_responses');
        Schema::dropIfExists('parent_options');
        Schema::dropIfExists('parent_questions');
        Schema::dropIfExists('interest_response_answer_options');
        Schema::dropIfExists('interest_response_answers');
        Schema::dropIfExists('interest_responses');
        Schema::dropIfExists('interest_options');
        Schema::dropIfExists('interest_questions');
    }
};
