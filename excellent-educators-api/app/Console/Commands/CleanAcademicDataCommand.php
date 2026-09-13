<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CleanAcademicDataCommand extends Command
{
    protected $signature = 'app:clean-academic-data';

    protected $description = 'Clean all students, teachers, and their related records from the database.';

    public function handle(): int
    {
        $this->info('Cleaning student, teacher, and related records...');

        DB::transaction(function () {
            // Delete child feedback records
            DB::table('monthly_feedback_items')->delete();
            DB::table('monthly_feedbacks')->delete();

            // Delete aptitude attempts and answers
            DB::table('aptitude_assessment_answers')->delete();
            DB::table('aptitude_assessment_result_dimensions')->delete();
            DB::table('aptitude_assessment_results')->delete();
            DB::table('aptitude_assessment_attempts')->delete();

            // Delete assessment scores
            DB::table('assessment_scores')->delete();

            // Delete batch and teacher assignments
            DB::table('batch_students')->delete();
            DB::table('batch_teachers')->delete();
            DB::table('master_teacher_assignments')->delete();
            DB::table('batches')->delete();
            if (Schema::hasTable('academic_levels')) {
                DB::table('academic_levels')->delete();
            }

            // Delete admin requests and notifications
            DB::table('admin_requests')->delete();
            DB::table('user_notifications')->delete();
            DB::table('audit_logs')->delete();

            // Delete profiles
            DB::table('student_profiles')->delete();
            DB::table('teacher_profiles')->delete();

            // Find all admin user IDs
            $adminUserIds = DB::table('model_has_roles')
                ->join('roles', 'roles.id', '=', 'model_has_roles.role_id')
                ->whereIn('roles.name', ['super_admin', 'operational_admin'])
                ->where('model_type', User::class)
                ->pluck('model_id')
                ->all();

            $nonAdminUserIds = DB::table('users')
                ->whereNotIn('id', $adminUserIds)
                ->pluck('id')
                ->all();

            if (! empty($nonAdminUserIds)) {
                DB::table('model_has_roles')->whereIn('model_id', $nonAdminUserIds)->delete();
                DB::table('model_has_permissions')->whereIn('model_id', $nonAdminUserIds)->delete();
                DB::table('personal_access_tokens')
                    ->where('tokenable_type', User::class)
                    ->whereIn('tokenable_id', $nonAdminUserIds)
                    ->delete();
                DB::table('sessions')->whereIn('user_id', $nonAdminUserIds)->delete();
                DB::table('users')->whereIn('id', $nonAdminUserIds)->delete();
            }

            // Reset student code sequence
            DB::table('student_code_sequences')->truncate();

            // Re-create default "Level 1" and "Batch 1"
            if (Schema::hasTable('academic_levels')) {
                $levelId = (string) new \Symfony\Component\Uid\Ulid();
                $currentYear = (int) date('Y');
                $currentMonth = (int) date('n');

                DB::table('academic_levels')->insert([
                    'id' => $levelId,
                    'name' => 'Level 1',
                    'academic_year' => $currentYear,
                    'status' => 'active',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                DB::table('batches')->insert([
                    'id' => (string) new \Symfony\Component\Uid\Ulid(),
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
        });

        $this->info('Database successfully cleaned of all student and teacher records.');

        return self::SUCCESS;
    }
}
