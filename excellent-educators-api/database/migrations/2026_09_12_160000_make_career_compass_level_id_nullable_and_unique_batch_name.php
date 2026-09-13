<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\Uid\Ulid;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('batches', function (Blueprint $table) {
            $table->foreignUlid('career_compass_level_id')->nullable()->change();
            $table->unique('name', 'batches_name_unique');
        });
    }

    public function down(): void
    {
        Schema::table('batches', function (Blueprint $table) {
            $table->dropUnique('batches_name_unique');
            $table->foreignUlid('career_compass_level_id')->nullable(false)->change();
        });
    }
};
