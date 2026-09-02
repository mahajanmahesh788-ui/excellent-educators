<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('aptitude_assessment_option_dimensions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('aptitude_assessment_option_id')
                ->constrained('aptitude_assessment_options')
                ->cascadeOnDelete();
            $table->string('dimension_code', 8);
            $table->unsignedSmallInteger('display_order')->default(1);
            $table->timestamps();
            $table->unique(
                ['aptitude_assessment_option_id', 'dimension_code'],
                'aptitude_option_dimension_unique',
            );
        });

        $codes = "'P','I','CF','L','CM','DM','CR','CU','TW','FA'";

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE aptitude_assessment_option_dimensions ADD CONSTRAINT aptitude_option_dimension_code_check CHECK (dimension_code IN ({$codes}))");
        }

        $options = DB::table('aptitude_assessment_options')
            ->select(['id', 'dimension_code'])
            ->orderBy('id')
            ->get();

        $now = now();
        foreach ($options as $option) {
            if (! is_string($option->dimension_code) || $option->dimension_code === '') {
                continue;
            }

            DB::table('aptitude_assessment_option_dimensions')->insert([
                'id' => (string) str()->ulid(),
                'aptitude_assessment_option_id' => $option->id,
                'dimension_code' => $option->dimension_code,
                'display_order' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE aptitude_assessment_options DROP CONSTRAINT IF EXISTS aptitude_options_dimension_code_check');
        }

        Schema::table('aptitude_assessment_options', function (Blueprint $table) {
            $table->dropColumn('dimension_code');
        });
    }

    public function down(): void
    {
        Schema::table('aptitude_assessment_options', function (Blueprint $table) {
            $table->string('dimension_code', 8)->nullable();
        });

        $rows = DB::table('aptitude_assessment_option_dimensions')
            ->orderBy('display_order')
            ->get()
            ->groupBy('aptitude_assessment_option_id');

        foreach ($rows as $optionId => $dimensions) {
            $first = $dimensions->first();
            if ($first !== null) {
                DB::table('aptitude_assessment_options')
                    ->where('id', $optionId)
                    ->update(['dimension_code' => $first->dimension_code]);
            }
        }

        Schema::dropIfExists('aptitude_assessment_option_dimensions');

        $codes = "'P','I','CF','L','CM','DM','CR','CU','TW','FA'";

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE aptitude_assessment_options ADD CONSTRAINT aptitude_options_dimension_code_check CHECK (dimension_code IN ({$codes}))");
        }
    }
};
