<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teacher_profiles', function (Blueprint $table) {
            $table->string('phone', 32)->nullable()->after('full_name');
            $table->string('whatsapp_number', 32)->nullable()->after('phone');
        });

        Schema::table('student_profiles', function (Blueprint $table) {
            $table->string('whatsapp_number', 32)->nullable()->after('phone');
        });
    }

    public function down(): void
    {
        Schema::table('teacher_profiles', function (Blueprint $table) {
            $table->dropColumn(['phone', 'whatsapp_number']);
        });

        Schema::table('student_profiles', function (Blueprint $table) {
            $table->dropColumn('whatsapp_number');
        });
    }
};
