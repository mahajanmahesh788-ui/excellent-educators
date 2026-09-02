<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_code_sequences', function (Blueprint $table) {
            $table->string('campaign_code', 16);
            $table->unsignedSmallInteger('academic_year');
            $table->unsignedInteger('last_seq')->default(0);
            $table->primary(['campaign_code', 'academic_year']);
        });

        Schema::create('student_profiles', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->unique()->constrained('users')->restrictOnDelete();
            $table->string('student_code', 32)->unique();
            $table->foreignUlid('career_compass_level_id')->constrained('career_compass_levels')->restrictOnDelete();
            $table->unsignedTinyInteger('class_grade');
            $table->string('full_name');
            $table->string('guardian_name')->nullable();
            $table->string('guardian_phone')->nullable();
            $table->string('status')->default('active');
            $table->unsignedSmallInteger('id_academic_year');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('teacher_profiles', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->unique()->constrained('users')->restrictOnDelete();
            $table->string('employee_code', 32)->nullable()->unique();
            $table->string('full_name');
            $table->string('status')->default('active');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('batches', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('career_compass_level_id')->constrained('career_compass_levels')->restrictOnDelete();
            $table->string('name');
            $table->unsignedSmallInteger('academic_year');
            $table->date('starts_on')->nullable();
            $table->date('ends_on')->nullable();
            $table->string('status')->default('active');
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('batch_students', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('batch_id')->constrained('batches')->restrictOnDelete();
            $table->foreignUlid('student_id')->constrained('student_profiles')->restrictOnDelete();
            $table->foreignUlid('enrolled_by')->constrained('users')->restrictOnDelete();
            $table->string('status')->default('active');
            $table->timestamp('enrolled_at');
            $table->timestamp('left_at')->nullable();
            $table->timestamps();
        });

        Schema::create('batch_teachers', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('batch_id')->constrained('batches')->restrictOnDelete();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->restrictOnDelete();
            $table->foreignUlid('assigned_by')->constrained('users')->restrictOnDelete();
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('master_teacher_assignments', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->restrictOnDelete();
            $table->foreignUlid('teacher_id')->constrained('teacher_profiles')->restrictOnDelete();
            $table->foreignUlid('assigned_by')->constrained('users')->restrictOnDelete();
            $table->timestamp('started_at');
            $table->timestamp('ended_at')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        DB::statement("CREATE UNIQUE INDEX batch_students_one_active_per_student ON batch_students (student_id) WHERE left_at IS NULL AND status = 'active'");
        DB::statement('CREATE UNIQUE INDEX batch_teachers_one_active_per_batch ON batch_teachers (batch_id) WHERE ended_at IS NULL');
        DB::statement('CREATE UNIQUE INDEX master_teacher_one_active_per_student ON master_teacher_assignments (student_id) WHERE ended_at IS NULL');

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::unprepared(<<<'SQL'
                CREATE OR REPLACE FUNCTION prevent_student_code_update()
                RETURNS trigger AS $$
                BEGIN
                    IF NEW.student_code IS DISTINCT FROM OLD.student_code THEN
                        RAISE EXCEPTION 'student_code is immutable';
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER student_profiles_student_code_immutable
                BEFORE UPDATE ON student_profiles
                FOR EACH ROW
                EXECUTE FUNCTION prevent_student_code_update();

                CREATE OR REPLACE FUNCTION enforce_batch_active_limit()
                RETURNS trigger AS $$
                DECLARE
                    active_count integer;
                BEGIN
                    IF NEW.status = 'active' AND NEW.left_at IS NULL THEN
                        SELECT COUNT(*) INTO active_count
                        FROM batch_students
                        WHERE batch_id = NEW.batch_id
                          AND status = 'active'
                          AND left_at IS NULL
                          AND id IS DISTINCT FROM NEW.id;
                        IF active_count >= 40 THEN
                            RAISE EXCEPTION 'This batch has reached the maximum limit of 40 active students.';
                        END IF;
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER batch_students_active_limit
                BEFORE INSERT OR UPDATE ON batch_students
                FOR EACH ROW
                EXECUTE FUNCTION enforce_batch_active_limit();
            SQL);
        }
    }

    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::unprepared('DROP TRIGGER IF EXISTS batch_students_active_limit ON batch_students');
            DB::unprepared('DROP TRIGGER IF EXISTS student_profiles_student_code_immutable ON student_profiles');
            DB::unprepared('DROP FUNCTION IF EXISTS enforce_batch_active_limit()');
            DB::unprepared('DROP FUNCTION IF EXISTS prevent_student_code_update()');
        }

        Schema::dropIfExists('master_teacher_assignments');
        Schema::dropIfExists('batch_teachers');
        Schema::dropIfExists('batch_students');
        Schema::dropIfExists('batches');
        Schema::dropIfExists('teacher_profiles');
        Schema::dropIfExists('student_profiles');
        Schema::dropIfExists('student_code_sequences');
    }
};
