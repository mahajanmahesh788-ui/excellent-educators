<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('weekly_learning_options', function (Blueprint $table) {
            $table->dropColumn('is_correct');
        });
    }

    public function down(): void
    {
        Schema::table('weekly_learning_options', function (Blueprint $table) {
            $table->boolean('is_correct')->default(false)->after('display_order');
        });
    }
};
