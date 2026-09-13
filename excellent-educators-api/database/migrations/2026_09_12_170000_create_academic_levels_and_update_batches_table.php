<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\Uid\Ulid;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Create academic_levels table
        Schema::create('academic_levels', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('name')->unique();
            $table->unsignedSmallInteger('academic_year');
            $table->string('status')->default('active');
            $table->timestamps();
            $table->softDeletes();
        });

        // 2. Clean old "Level 1" batch placeholder row if exists
        DB::table('batches')->where('name', 'Level 1')->delete();

        // 3. Drop batches_name_unique on batches
        Schema::table('batches', function (Blueprint $table) {
            $table->dropUnique('batches_name_unique');
            $table->foreignUlid('level_id')->nullable()->constrained('academic_levels')->cascadeOnDelete();
            $table->unsignedSmallInteger('year')->nullable();
            $table->unsignedTinyInteger('month')->nullable();
            $table->unsignedInteger('enrolled_watermark')->default(0);
        });

        // 4. Add level_id to student_profiles
        Schema::table('student_profiles', function (Blueprint $table) {
            $table->foreignUlid('level_id')->nullable()->constrained('academic_levels')->nullOnDelete();
        });

        // 5. Drop 40-student trigger if using PostgreSQL
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::unprepared(<<<'SQL'
                DROP TRIGGER IF EXISTS batch_students_active_limit ON batch_students;
                DROP FUNCTION IF EXISTS enforce_batch_active_limit();
            SQL);
        }

        // 6. Seed default Level 1 and its Batch 1
        $currentYear = (int) date('Y');
        $currentMonth = (int) date('n');
        $levelId = (string) new Ulid();

        DB::table('academic_levels')->insert([
            'id' => $levelId,
            'name' => 'Level 1',
            'academic_year' => $currentYear,
            'status' => 'active',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('batches')->insert([
            'id' => (string) new Ulid(),
            'level_id' => $levelId,
            'name' => 'Batch 1',
            'academic_year' => $currentYear,
            'year' => $currentYear,
            'month' => $currentMonth,
            'status' => 'active',
            'enrolled_watermark' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::table('student_profiles', function (Blueprint $table) {
            $table->dropConstrainedForeignId('level_id');
        });

        Schema::table('batches', function (Blueprint $table) {
            $table->dropConstrainedForeignId('level_id');
            $table->dropColumn(['year', 'month', 'enrolled_watermark']);
            $table->unique('name', 'batches_name_unique');
        });

        Schema::dropIfExists('academic_levels');
    }
};
