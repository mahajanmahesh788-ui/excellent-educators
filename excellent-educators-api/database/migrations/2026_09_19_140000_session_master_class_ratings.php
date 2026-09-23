<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('monthly_feedbacks', function (Blueprint $table) {
            $table->dropUnique(['student_id', 'year', 'month']);
            $table->foreignUlid('session_booking_id')
                ->nullable()
                ->after('master_teacher_id')
                ->constrained('session_bookings')
                ->nullOnDelete();
            $table->text('positive_points')->nullable()->after('session_date');
            $table->text('areas_for_improvement')->nullable()->after('positive_points');
            $table->text('discussed_in_class')->nullable()->after('areas_for_improvement');
            $table->unique('session_booking_id');
        });

        $rows = DB::table('monthly_feedbacks')->get();
        foreach ($rows as $row) {
            $item = DB::table('monthly_feedback_items')
                ->where('monthly_feedback_id', $row->id)
                ->orderBy('created_at')
                ->first();
            if ($item === null) {
                continue;
            }
            DB::table('monthly_feedbacks')->where('id', $row->id)->update([
                'positive_points' => $item->positive_points,
                'areas_for_improvement' => $item->areas_for_improvement,
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('monthly_feedbacks', function (Blueprint $table) {
            $table->dropUnique(['session_booking_id']);
            $table->dropConstrainedForeignId('session_booking_id');
            $table->dropColumn(['positive_points', 'areas_for_improvement', 'discussed_in_class']);
            $table->unique(['student_id', 'year', 'month']);
        });
    }
};
