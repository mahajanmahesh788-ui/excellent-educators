<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('student_profiles', 'career_compass_level_id')) {
            Schema::table('student_profiles', function (Blueprint $table) {
                $table->dropConstrainedForeignId('career_compass_level_id');
            });
        }

        if (Schema::hasColumn('batches', 'career_compass_level_id')) {
            Schema::table('batches', function (Blueprint $table) {
                $table->dropConstrainedForeignId('career_compass_level_id');
            });
        }

        if (Schema::hasTable('aptitude_assessments') && Schema::hasColumn('aptitude_assessments', 'career_compass_level_id')) {
            Schema::table('aptitude_assessments', function (Blueprint $table) {
                $table->dropConstrainedForeignId('career_compass_level_id');
            });
        }

        Schema::dropIfExists('career_compass_levels');
    }

    public function down(): void
    {
        // irreversible cleanup
    }
};
