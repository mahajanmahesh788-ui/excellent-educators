<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CleanAcademicDataCommand extends Command
{
    protected $signature = 'app:clean-academic-data
                            {--force : Run without confirmation}
                            {--seed : After clean, reseed demo teachers/students/levels/weeks/assessments}';

    protected $description = 'Clean all students, teachers, assessments, levels, and related records. Keeps admin users and system config. Use --seed to reload DemoSeedData.';

    public function handle(): int
    {
        if (! $this->option('force') && ! $this->confirm('This will delete ALL students, teachers, assessments, and levels. Continue?')) {
            $this->warn('Cancelled.');

            return self::SUCCESS;
        }

        $this->info('Cleaning students, teachers, assessments, levels, and related records...');

        DB::transaction(function () {
            $this->deleteIfExists([
                // Feedback
                'monthly_feedback_items',
                'monthly_feedbacks',

                // Weekly learning attempts + content
                'weekly_assignment_attempts',
                'weekly_learning_option_dimensions',
                'weekly_learning_options',
                'weekly_learning_questions',
                'weekly_learnings',

                // Student onboarding responses
                'interest_response_answer_options',
                'interest_response_answers',
                'interest_responses',
                'parent_response_answers',
                'parent_responses',

                // Aptitude assessments (full tree)
                'aptitude_assessment_answers',
                'aptitude_assessment_result_dimensions',
                'aptitude_assessment_results',
                'aptitude_assessment_attempts',
                'aptitude_assessment_option_dimensions',
                'aptitude_assessment_options',
                'aptitude_assessment_questions',
                'academic_level_assessments',
                'aptitude_assessments',

                // Legacy assessments
                'assessment_scores',
                'assessment_versions',
                'assessments',

                // Scheduling / attendance tied to students & teachers
                'class_join_events',
                'class_attendances',
                'attendance_issues',
                'session_bookings',
                'teacher_leave_reassignments',
                'teacher_leaves',
                'teacher_breaks',
                'teacher_weekly_offs',
                'teacher_availability_overrides',
                'teacher_availability_rules',
                'teacher_daily_meetings',

                // Payments
                'student_payment_plan_audits',
                'student_payments',
                'student_payment_plans',
                'student_master_class_balances',

                // Journeys / activity
                'student_level_journeys',
                'student_activity_events',
                'admin_activity_events',

                // Level / batch / mentoring
                'batch_students',
                'batch_teachers',
                'master_teacher_assignments',
                'academic_level_teachers',
                'batches',
                'academic_levels',

                // Requests / notifications / audit
                'admin_requests',
                'user_notifications',
                'audit_logs',

                // Profiles
                'student_profiles',
                'teacher_profiles',
            ]);

            // Find all admin user IDs (keep these)
            $adminUserIds = DB::table('model_has_roles')
                ->join('roles', 'roles.id', '=', 'model_has_roles.role_id')
                ->whereIn('roles.name', ['super_admin', 'operational_admin', 'sub_admin'])
                ->where('model_type', User::class)
                ->pluck('model_id')
                ->all();

            $nonAdminUserIds = DB::table('users')
                ->whereNotIn('id', $adminUserIds)
                ->pluck('id')
                ->all();

            if ($nonAdminUserIds !== []) {
                DB::table('model_has_roles')->whereIn('model_id', $nonAdminUserIds)->delete();
                DB::table('model_has_permissions')->whereIn('model_id', $nonAdminUserIds)->delete();
                DB::table('personal_access_tokens')
                    ->where('tokenable_type', User::class)
                    ->whereIn('tokenable_id', $nonAdminUserIds)
                    ->delete();
                if (Schema::hasTable('sessions')) {
                    DB::table('sessions')->whereIn('user_id', $nonAdminUserIds)->delete();
                }
                DB::table('users')->whereIn('id', $nonAdminUserIds)->delete();
            }

            // Shared Google Meet tokens are not per-user; leave them unless wiping all.
            // (table has no user_id column)

            if (Schema::hasTable('student_code_sequences')) {
                DB::table('student_code_sequences')->truncate();
            }

            // Re-create default Level 1 + Batch 1
            if (Schema::hasTable('academic_levels')) {
                $levelId = (string) new \Symfony\Component\Uid\Ulid();
                $currentYear = (int) date('Y');
                $currentMonth = (int) date('n');

                DB::table('academic_levels')->insert([
                    'id' => $levelId,
                    'name' => 'Level 1',
                    'number' => 1,
                    'academic_year' => $currentYear,
                    'status' => 'active',
                    'master_classes_per_month' => 1,
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
                    'status' => 'inactive',
                    'enrolled_watermark' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        });

        $this->info('Done. Students, teachers, assessments, and levels cleared. Fresh Level 1 / Batch 1 created. Admin accounts kept.');

        if ($this->option('seed')) {
            if (app()->environment('production')) {
                $this->error('Refusing to seed demo data in production.');

                return self::FAILURE;
            }

            $this->newLine();
            $this->info('Reseeding demo static data from DemoSeedData...');
            $this->call('db:seed', [
                '--class' => \Database\Seeders\DemoDataSeeder::class,
                '--force' => true,
            ]);
        }

        return self::SUCCESS;
    }

    /**
     * @param  list<string>  $tables
     */
    private function deleteIfExists(array $tables): void
    {
        foreach ($tables as $table) {
            if (! Schema::hasTable($table)) {
                continue;
            }

            DB::table($table)->delete();
            $this->line("  cleared {$table}");
        }
    }
}
