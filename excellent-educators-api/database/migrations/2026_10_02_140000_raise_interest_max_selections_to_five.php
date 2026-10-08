<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Existing questions still on the old default of 3 → 5.
        if (Schema::hasTable('interest_questions')) {
            DB::table('interest_questions')
                ->where('max_selections', 3)
                ->update(['max_selections' => 5]);
        }
    }

    public function down(): void
    {
        // No-op: do not force existing rows back down.
    }
};
