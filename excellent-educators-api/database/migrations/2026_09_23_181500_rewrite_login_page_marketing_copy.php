<?php

use App\Models\LoginPageContent;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
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
        // Copy was replaced because it was not original. No restore.
    }
};
