<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teacher_daily_meetings', function (Blueprint $table) {
            $table->string('google_meet_url', 2048)->nullable()->after('meet_url');
            $table->string('meet_url_source', 20)->default('google')->after('google_meet_url');
        });
    }

    public function down(): void
    {
        Schema::table('teacher_daily_meetings', function (Blueprint $table) {
            $table->dropColumn(['google_meet_url', 'meet_url_source']);
        });
    }
};
