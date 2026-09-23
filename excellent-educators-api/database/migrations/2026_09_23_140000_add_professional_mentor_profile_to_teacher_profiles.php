<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teacher_profiles', function (Blueprint $table) {
            $table->string('photo_url', 2048)->nullable()->after('address');
            $table->string('professional_title', 120)->nullable()->after('photo_url');
            $table->text('bio')->nullable()->after('professional_title');
            $table->string('experience_summary', 255)->nullable()->after('bio');
            $table->json('guidance_areas')->nullable()->after('experience_summary');
            $table->json('mentoring_approach')->nullable()->after('guidance_areas');
            $table->json('education')->nullable()->after('mentoring_approach');
            $table->json('certifications')->nullable()->after('education');
            $table->json('experience')->nullable()->after('certifications');
        });
    }

    public function down(): void
    {
        Schema::table('teacher_profiles', function (Blueprint $table) {
            $table->dropColumn([
                'photo_url',
                'professional_title',
                'bio',
                'experience_summary',
                'guidance_areas',
                'mentoring_approach',
                'education',
                'certifications',
                'experience',
            ]);
        });
    }
};
