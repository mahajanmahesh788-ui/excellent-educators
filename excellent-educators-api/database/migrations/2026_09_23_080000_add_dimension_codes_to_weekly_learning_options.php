<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weekly_learning_option_dimensions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('weekly_learning_option_id')
                ->constrained('weekly_learning_options')
                ->cascadeOnDelete();
            $table->string('dimension_code', 2);
            $table->unsignedTinyInteger('display_order')->default(1);
            $table->timestamps();
            $table->unique(
                ['weekly_learning_option_id', 'dimension_code'],
                'weekly_option_dimension_unique',
            );
        });

        $now = now();
        DB::table('weekly_learning_options')
            ->select('id')
            ->orderBy('id')
            ->chunk(500, function ($options) use ($now): void {
                DB::table('weekly_learning_option_dimensions')->insert(
                    $options->map(fn ($option) => [
                        'id' => (string) Str::ulid(),
                        'weekly_learning_option_id' => $option->id,
                        'dimension_code' => 'TW',
                        'display_order' => 1,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ])->all(),
                );
            });
    }

    public function down(): void
    {
        Schema::dropIfExists('weekly_learning_option_dimensions');
    }
};
