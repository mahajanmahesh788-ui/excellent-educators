<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('academic_levels', function (Blueprint $table) {
            $table->unsignedTinyInteger('master_classes_per_month')->default(1)->after('status');
        });

        Schema::table('student_profiles', function (Blueprint $table) {
            $table->unsignedTinyInteger('master_classes_per_month')->nullable()->after('level_id');
        });

        Schema::create('student_master_class_balances', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->unsignedSmallInteger('year');
            $table->unsignedTinyInteger('month');
            $table->unsignedTinyInteger('allotment');
            $table->unsignedTinyInteger('remaining');
            $table->timestamps();

            $table->unique(['student_id', 'year', 'month'], 'student_mc_balance_unique');
        });

        Schema::create('student_activity_events', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->string('type');
            $table->string('message');
            $table->timestamp('occurred_at');
            $table->foreignUlid('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('related_type')->nullable();
            $table->ulid('related_id')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['student_id', 'occurred_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_activity_events');
        Schema::dropIfExists('student_master_class_balances');
        Schema::table('student_profiles', function (Blueprint $table) {
            $table->dropColumn('master_classes_per_month');
        });
        Schema::table('academic_levels', function (Blueprint $table) {
            $table->dropColumn('master_classes_per_month');
        });
    }
};
