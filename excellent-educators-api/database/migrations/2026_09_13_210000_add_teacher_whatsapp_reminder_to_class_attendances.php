<?php

return new class extends \Illuminate\Database\Migrations\Migration
{
    public function up(): void
    {
        \Illuminate\Support\Facades\Schema::table('class_attendances', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->timestamp('teacher_whatsapp_reminder_sent_at')->nullable()->after('teacher_join_count');
        });
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\Schema::table('class_attendances', function (\Illuminate\Database\Schema\Blueprint $table) {
            $table->dropColumn('teacher_whatsapp_reminder_sent_at');
        });
    }
};
