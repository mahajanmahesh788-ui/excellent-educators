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
            $table->text('address')->nullable()->after('whatsapp_number');
        });

        DB::table('career_compass_levels')
            ->where('code', 'cc1')
            ->update(['class_from' => 5]);
    }

    public function down(): void
    {
        Schema::table('student_profiles', function (Blueprint $table) {
            $table->dropColumn('address');
        });

        DB::table('career_compass_levels')
            ->where('code', 'cc1')
            ->update(['class_from' => 6]);
    }
};
