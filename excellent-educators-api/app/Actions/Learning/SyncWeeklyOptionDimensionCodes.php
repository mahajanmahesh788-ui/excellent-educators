<?php

namespace App\Actions\Learning;

use App\Enums\DimensionCode;
use App\Models\WeeklyLearningOption;
use Illuminate\Validation\ValidationException;

class SyncWeeklyOptionDimensionCodes
{
    /**
     * @param  list<string>  $codes
     */
    public function execute(WeeklyLearningOption $option, array $codes): void
    {
        $normalized = array_values(array_unique(array_filter(
            $codes,
            fn ($code) => is_string($code) && $code !== '',
        )));

        if ($normalized === [] || count($normalized) > 3) {
            throw ValidationException::withMessages([
                'dimension_codes' => 'Each option needs one to three dimension codes.',
            ]);
        }

        foreach ($normalized as $code) {
            if (! in_array($code, DimensionCode::values(), true)) {
                throw ValidationException::withMessages([
                    'dimension_codes' => 'One or more dimension codes are invalid.',
                ]);
            }
        }

        $option->dimensionCodes()->delete();
        foreach ($normalized as $index => $code) {
            $option->dimensionCodes()->create([
                'dimension_code' => $code,
                'display_order' => $index + 1,
            ]);
        }
    }
}
