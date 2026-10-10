<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('session_bookings', function (Blueprint $table) {
            $table->string('meet_url', 2048)->nullable()->after('status');
            $table->string('google_meeting_space_id', 255)->nullable()->after('meet_url');
        });
    }

    public function down(): void
    {
        Schema::table('session_bookings', function (Blueprint $table) {
            $table->dropColumn(['meet_url', 'google_meeting_space_id']);
        });
    }
};
