<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $duplicateGroups = DB::table('monthly_feedbacks')
            ->select('student_id', 'year', 'month')
            ->groupBy('student_id', 'year', 'month')
            ->havingRaw('COUNT(*) > 1')
            ->get();

        foreach ($duplicateGroups as $group) {
            $keepId = DB::table('monthly_feedbacks')
                ->where('student_id', $group->student_id)
                ->where('year', $group->year)
                ->where('month', $group->month)
                ->orderByDesc('submitted_at')
                ->value('id');

            if ($keepId === null) {
                continue;
            }

            $removeIds = DB::table('monthly_feedbacks')
                ->where('student_id', $group->student_id)
                ->where('year', $group->year)
                ->where('month', $group->month)
                ->where('id', '!=', $keepId)
                ->pluck('id');

            if ($removeIds->isNotEmpty()) {
                DB::table('monthly_feedback_items')->whereIn('monthly_feedback_id', $removeIds)->delete();
                DB::table('monthly_feedbacks')->whereIn('id', $removeIds)->delete();
            }
        }

        Schema::table('monthly_feedbacks', function (Blueprint $table) {
            $table->unique(['student_id', 'year', 'month']);
        });
    }

    public function down(): void
    {
        Schema::table('monthly_feedbacks', function (Blueprint $table) {
            $table->dropUnique(['student_id', 'year', 'month']);
        });
    }
};
