<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teacher_leaves', function (Blueprint $table) {
            $table->ulid('request_group_id')->nullable()->after('id')->index();
            $table->string('status', 32)->default('approved')->after('reason');
            $table->foreignUlid('reviewed_by')->nullable()->after('status')->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable()->after('reviewed_by');
            $table->string('rejection_reason')->nullable()->after('reviewed_at');
        });

        $leaves = DB::table('teacher_leaves')->whereNull('request_group_id')->get(['id']);
        foreach ($leaves as $leave) {
            DB::table('teacher_leaves')->where('id', $leave->id)->update([
                'request_group_id' => (string) Str::ulid(),
                'status' => 'approved',
            ]);
        }

        Schema::create('teacher_leave_reassignments', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->ulid('leave_request_group_id')->index();
            $table->foreignUlid('booking_id')->constrained('session_bookings')->cascadeOnDelete();
            $table->foreignUlid('replacement_teacher_id')->nullable()->constrained('teacher_profiles')->nullOnDelete();
            $table->foreignUlid('assigned_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('assigned_at')->nullable();
            $table->timestamps();

            $table->unique(['leave_request_group_id', 'booking_id'], 'leave_reassign_group_booking_unique');
        });

        Schema::table('session_bookings', function (Blueprint $table) {
            $table->foreignUlid('reassigned_from_teacher_id')
                ->nullable()
                ->after('teacher_id')
                ->constrained('teacher_profiles')
                ->nullOnDelete();
            $table->timestamp('reassigned_at')->nullable()->after('reassigned_from_teacher_id');
        });
    }

    public function down(): void
    {
        Schema::table('session_bookings', function (Blueprint $table) {
            $table->dropConstrainedForeignId('reassigned_from_teacher_id');
            $table->dropColumn('reassigned_at');
        });

        Schema::dropIfExists('teacher_leave_reassignments');

        Schema::table('teacher_leaves', function (Blueprint $table) {
            $table->dropConstrainedForeignId('reviewed_by');
            $table->dropColumn(['request_group_id', 'status', 'reviewed_at', 'rejection_reason']);
        });
    }
};
