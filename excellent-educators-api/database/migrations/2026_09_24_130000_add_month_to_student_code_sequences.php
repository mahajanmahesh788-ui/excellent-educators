<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_code_sequences_ym', function (Blueprint $table) {
            $table->string('campaign_code', 16);
            $table->unsignedSmallInteger('academic_year');
            $table->unsignedTinyInteger('month');
            $table->unsignedInteger('last_seq')->default(0);
            $table->primary(['campaign_code', 'academic_year', 'month']);
        });

        if (Schema::hasTable('student_code_sequences')) {
            $rows = DB::table('student_code_sequences')->get();
            foreach ($rows as $row) {
                DB::table('student_code_sequences_ym')->insert([
                    'campaign_code' => $row->campaign_code,
                    'academic_year' => $row->academic_year,
                    'month' => 1,
                    'last_seq' => $row->last_seq,
                ]);
            }
            Schema::drop('student_code_sequences');
        }

        Schema::rename('student_code_sequences_ym', 'student_code_sequences');
    }

    public function down(): void
    {
        Schema::create('student_code_sequences_year', function (Blueprint $table) {
            $table->string('campaign_code', 16);
            $table->unsignedSmallInteger('academic_year');
            $table->unsignedInteger('last_seq')->default(0);
            $table->primary(['campaign_code', 'academic_year']);
        });

        if (Schema::hasTable('student_code_sequences')) {
            $grouped = DB::table('student_code_sequences')
                ->select('campaign_code', 'academic_year', DB::raw('max(last_seq) as last_seq'))
                ->groupBy('campaign_code', 'academic_year')
                ->get();

            foreach ($grouped as $row) {
                DB::table('student_code_sequences_year')->insert([
                    'campaign_code' => $row->campaign_code,
                    'academic_year' => $row->academic_year,
                    'last_seq' => $row->last_seq,
                ]);
            }

            Schema::drop('student_code_sequences');
        }

        Schema::rename('student_code_sequences_year', 'student_code_sequences');
    }
};
