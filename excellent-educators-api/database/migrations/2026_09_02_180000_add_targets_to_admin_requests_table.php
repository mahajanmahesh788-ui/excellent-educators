<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('admin_requests', function (Blueprint $table): void {
            $table->string('request_type')->default('general')->after('requester_type');
            $table->foreignUlid('student_id')->nullable()->after('description')->constrained('student_profiles')->nullOnDelete();
            $table->foreignUlid('batch_id')->nullable()->after('student_id')->constrained('batches')->nullOnDelete();

            $table->index(['request_type', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('admin_requests', function (Blueprint $table): void {
            $table->dropIndex(['request_type', 'status']);
            $table->dropConstrainedForeignId('batch_id');
            $table->dropConstrainedForeignId('student_id');
            $table->dropColumn('request_type');
        });
    }
};
