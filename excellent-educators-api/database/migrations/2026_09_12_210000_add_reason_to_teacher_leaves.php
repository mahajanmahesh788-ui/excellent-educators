<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teacher_leaves', function (Blueprint $table) {
            $table->string('reason', 255)->nullable()->after('is_full_day');
        });
    }

    public function down(): void
    {
        Schema::table('teacher_leaves', function (Blueprint $table) {
            $table->dropColumn('reason');
        });
    }
};
