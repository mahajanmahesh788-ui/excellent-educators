<?php

use App\Models\LoginPageContent;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('login_page_contents', function (Blueprint $table) {
            $table->string('why_heading')->nullable()->after('trust_signals');
            $table->json('stories')->nullable()->after('why_heading');
        });

        $defaults = LoginPageContent::defaultAttributes();

        DB::table('login_page_contents')->update([
            'trust_signals' => json_encode($defaults['trust_signals']),
            'why_heading' => $defaults['why_heading'],
            'pillars' => json_encode($defaults['pillars']),
            'stories' => json_encode($defaults['stories']),
            'testimonials_heading' => $defaults['testimonials_heading'],
            'testimonials' => json_encode($defaults['testimonials']),
        ]);
    }

    public function down(): void
    {
        Schema::table('login_page_contents', function (Blueprint $table) {
            $table->dropColumn(['why_heading', 'stories']);
        });
    }
};
