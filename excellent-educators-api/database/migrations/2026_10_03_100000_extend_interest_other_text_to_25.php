<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('interest_response_answers')) {
            return;
        }

        $driver = Schema::getConnection()->getDriverName();
        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE interest_response_answers ALTER COLUMN other_text TYPE varchar(25)');
        } elseif ($driver === 'mysql') {
            DB::statement('ALTER TABLE interest_response_answers MODIFY other_text VARCHAR(25) NULL');
        }
        // sqlite: length is not enforced the same way; skip.
    }

    public function down(): void
    {
        if (! Schema::hasTable('interest_response_answers')) {
            return;
        }

        $driver = Schema::getConnection()->getDriverName();
        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE interest_response_answers ALTER COLUMN other_text TYPE varchar(15)');
        } elseif ($driver === 'mysql') {
            DB::statement('ALTER TABLE interest_response_answers MODIFY other_text VARCHAR(15) NULL');
        }
    }
};
