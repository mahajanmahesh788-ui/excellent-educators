<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('student_profiles')
            ->whereNotNull('phone')
            ->orderBy('id')
            ->get(['id', 'phone'])
            ->each(function ($row): void {
                $normalized = preg_replace('/\D+/', '', (string) $row->phone) ?? '';
                if ($normalized !== '') {
                    DB::table('student_profiles')->where('id', $row->id)->update(['phone' => $normalized]);
                }
            });

        Schema::table('student_profiles', function (Blueprint $table) {
            $table->unique('phone');
        });
    }

    public function down(): void
    {
        Schema::table('student_profiles', function (Blueprint $table) {
            $table->dropUnique(['phone']);
        });
    }
};
