<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Batches must stay inactive until they reach max students (default 50)
 * or an admin activates them. Seeded Batch 1 was incorrectly created as active.
 */
return new class extends Migration
{
    public function up(): void
    {
        $max = (int) (DB::table('app_settings')->where('key', 'max_active_students')->value('value')
            ?? config('excellent_educators.batch.max_active_students', 50));
        if ($max < 1) {
            $max = 50;
        }

        // New rows default to inactive.
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE batches ALTER COLUMN status SET DEFAULT 'inactive'");
        } else {
            Schema::table('batches', function (Blueprint $table) {
                $table->string('status')->default('inactive')->change();
            });
        }

        // Fix batches that are still filling up (not full yet).
        DB::table('batches')
            ->where('status', 'active')
            ->where('enrolled_watermark', '<', $max)
            ->update([
                'status' => 'inactive',
                'updated_at' => now(),
            ]);
    }

    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE batches ALTER COLUMN status SET DEFAULT 'active'");
        } else {
            Schema::table('batches', function (Blueprint $table) {
                $table->string('status')->default('active')->change();
            });
        }
    }
};
