<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('weekly_learnings', function (Blueprint $table) {
            $table->text('comprehension_paragraph')->nullable()->after('video_url');
        });

        Schema::table('weekly_learning_questions', function (Blueprint $table) {
            $table->string('section', 32)->default('main')->after('question_type');
            $table->index(['weekly_learning_id', 'section']);
        });
    }

    public function down(): void
    {
        Schema::table('weekly_learning_questions', function (Blueprint $table) {
            $table->dropIndex(['weekly_learning_id', 'section']);
            $table->dropColumn('section');
        });

        Schema::table('weekly_learnings', function (Blueprint $table) {
            $table->dropColumn('comprehension_paragraph');
        });
    }
};
