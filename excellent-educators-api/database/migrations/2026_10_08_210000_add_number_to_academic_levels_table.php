<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('academic_levels', function (Blueprint $table) {
            $table->unsignedTinyInteger('number')->nullable()->after('name');
        });

        $levels = DB::table('academic_levels')->orderBy('created_at')->get(['id', 'name']);
        $used = [];

        foreach ($levels as $level) {
            $number = null;
            if (preg_match('/^Level\s+(\d+)$/i', trim((string) $level->name), $matches) === 1) {
                $candidate = (int) $matches[1];
                if ($candidate >= 1 && $candidate <= 10 && ! in_array($candidate, $used, true)) {
                    $number = $candidate;
                }
            }

            if ($number === null) {
                for ($i = 1; $i <= 10; $i++) {
                    if (! in_array($i, $used, true)) {
                        $number = $i;
                        break;
                    }
                }
            }

            if ($number === null) {
                continue;
            }

            $used[] = $number;
            DB::table('academic_levels')->where('id', $level->id)->update([
                'number' => $number,
                'name' => 'Level '.$number,
            ]);
        }

        Schema::table('academic_levels', function (Blueprint $table) {
            $table->index('number');
        });
    }

    public function down(): void
    {
        Schema::table('academic_levels', function (Blueprint $table) {
            $table->dropIndex(['number']);
            $table->dropColumn('number');
        });
    }
};
