<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Fresh installs already get the correct schema from the create migration.
        // This migration upgrades existing databases that still cascade-delete payments.
        if (! Schema::hasColumn('student_payment_plans', 'dead_amount')) {
            Schema::table('student_payment_plans', function (Blueprint $table) {
                $table->decimal('dead_amount', 12, 2)->default(0);
                $table->string('student_name_snapshot', 160)->nullable();
                $table->string('student_code_snapshot', 40)->nullable();
                $table->timestamp('withdrawn_at')->nullable();
            });
        }

        if (! Schema::hasColumn('student_payments', 'student_name_snapshot')) {
            Schema::table('student_payments', function (Blueprint $table) {
                $table->string('student_name_snapshot', 160)->nullable();
                $table->string('student_code_snapshot', 40)->nullable();
            });
        }

        if (Schema::getConnection()->getDriverName() !== 'pgsql') {
            return;
        }

        $this->ensureNullOnDelete('student_payment_plans');
        $this->ensureNullOnDelete('student_payments');
        $this->ensureNullOnDelete('student_payment_plan_audits');
    }

    public function down(): void
    {
        // Irreversible data-preserving upgrade.
    }

    private function ensureNullOnDelete(string $table): void
    {
        $foreign = DB::selectOne(
            "select conname
             from pg_constraint
             where contype = 'f'
               and conrelid = ?::regclass
               and pg_get_constraintdef(oid) like '%student_id%'",
            [$table],
        );

        if ($foreign !== null && isset($foreign->conname)) {
            DB::statement("ALTER TABLE {$table} DROP CONSTRAINT {$foreign->conname}");
        }

        DB::statement("ALTER TABLE {$table} ALTER COLUMN student_id DROP NOT NULL");
        DB::statement(
            "ALTER TABLE {$table}
             ADD CONSTRAINT {$table}_student_id_foreign
             FOREIGN KEY (student_id) REFERENCES student_profiles(id) ON DELETE SET NULL"
        );
    }
};
