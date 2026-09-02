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
            $table->date('session_date')->nullable()->after('month');
        });

        DB::table('monthly_feedbacks')->update([
            'session_date' => DB::raw('date(submitted_at)'),
        ]);

        Schema::table('monthly_feedbacks', function (Blueprint $table) {
            $table->date('session_date')->nullable(false)->change();
            $table->index(['student_id', 'year', 'month']);
        });
    }

    public function down(): void
    {
        Schema::table('monthly_feedbacks', function (Blueprint $table) {
            $table->dropIndex(['student_id', 'year', 'month']);
            $table->dropColumn('session_date');
            $table->unique(['student_id', 'year', 'month']);
        });
    }
};
