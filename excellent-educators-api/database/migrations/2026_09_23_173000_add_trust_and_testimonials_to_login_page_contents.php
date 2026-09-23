<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('login_page_contents', function (Blueprint $table) {
            $table->json('trust_signals')->nullable()->after('pillars');
            $table->string('testimonials_heading')->nullable()->after('trust_signals');
            $table->json('testimonials')->nullable()->after('testimonials_heading');
        });

        $defaults = [
            'trust_signals' => json_encode([
                [
                    'icon' => 'verified_outlined',
                    'value' => 'Mentor-led',
                    'label' => 'guided growth path',
                ],
                [
                    'icon' => 'star_outline',
                    'value' => 'Weekly',
                    'label' => 'learning journal & feedback',
                ],
                [
                    'icon' => 'public_outlined',
                    'value' => '1:1',
                    'label' => 'sessions with master teachers',
                ],
            ]),
            'testimonials_heading' => 'Students, parents, and teachers love us',
            'testimonials' => json_encode([
                [
                    'quote' => 'The weekly journal and mentor sessions finally gave my child a clear direction.',
                    'attribution' => 'Parent',
                    'role' => 'Parent',
                ],
                [
                    'quote' => 'Introduction calls feel personal, and feedback helps me improve every month.',
                    'attribution' => 'Student',
                    'role' => 'Student',
                ],
                [
                    'quote' => 'Structured weeks make mentoring practical, not just motivational talks.',
                    'attribution' => 'Master Teacher',
                    'role' => 'Teacher',
                ],
            ]),
        ];

        DB::table('login_page_contents')->update($defaults);
    }

    public function down(): void
    {
        Schema::table('login_page_contents', function (Blueprint $table) {
            $table->dropColumn(['trust_signals', 'testimonials_heading', 'testimonials']);
        });
    }
};
