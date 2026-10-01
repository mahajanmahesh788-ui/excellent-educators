<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('admin_requests', function (Blueprint $table): void {
            $table->foreignUlid('from_level_id')
                ->nullable()
                ->after('batch_id')
                ->constrained('academic_levels')
                ->nullOnDelete();
            $table->foreignUlid('target_level_id')
                ->nullable()
                ->after('from_level_id')
                ->constrained('academic_levels')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('admin_requests', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('target_level_id');
            $table->dropConstrainedForeignId('from_level_id');
        });
    }
};
