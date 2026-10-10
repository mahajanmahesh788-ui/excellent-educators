<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('weekly_learnings', function (Blueprint $table) {
            $table->string('video_title', 180)->nullable()->after('video_url');
        });
    }

    public function down(): void
    {
        Schema::table('weekly_learnings', function (Blueprint $table) {
            $table->dropColumn('video_title');
        });
    }
};
