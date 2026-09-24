<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('student_profiles', function (Blueprint $table) {
            $table->foreignUlid('created_by_user_id')
                ->nullable()
                ->after('user_id')
                ->constrained('users')
                ->nullOnDelete();
        });

        // Backfill from existing agent/sub-admin activity logs when student_id was stored.
        $events = DB::table('admin_activity_events')
            ->where('type', 'student.create')
            ->whereNotNull('meta')
            ->orderBy('occurred_at')
            ->get(['actor_id', 'meta']);

        foreach ($events as $event) {
            $meta = is_string($event->meta) ? json_decode($event->meta, true) : $event->meta;
            if (! is_array($meta)) {
                continue;
            }
            $studentId = $meta['student_id'] ?? null;
            if (! is_string($studentId) || $studentId === '') {
                continue;
            }

            DB::table('student_profiles')
                ->where('id', $studentId)
                ->whereNull('created_by_user_id')
                ->update(['created_by_user_id' => $event->actor_id]);
        }
    }

    public function down(): void
    {
        Schema::table('student_profiles', function (Blueprint $table) {
            $table->dropConstrainedForeignId('created_by_user_id');
        });
    }
};
