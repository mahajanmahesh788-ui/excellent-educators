<?php

namespace App\Actions\Assessments;

use App\Enums\DimensionCode;
use App\Models\AptitudeAssessmentOption;
use Illuminate\Validation\ValidationException;

class SyncOptionDimensionCodes
{
    /**
     * @param  list<string>  $codes
     */
    public function execute(AptitudeAssessmentOption $option, array $codes): void
    {
        $normalized = [];
        foreach ($codes as $code) {
            if (! is_string($code) || $code === '') {
                continue;
            }
            if (! in_array($code, $normalized, true)) {
                $normalized[] = $code;
            }
        }

        if ($normalized === []) {
            throw ValidationException::withMessages([
                'dimension_codes' => 'Each option must have at least one dimension code.',
            ]);
        }

        if (count($normalized) > 3) {
            throw ValidationException::withMessages([
                'dimension_codes' => 'Each option may have at most three dimension codes.',
            ]);
        }

        $valid = DimensionCode::values();
        foreach ($normalized as $code) {
            if (! in_array($code, $valid, true)) {
                throw ValidationException::withMessages([
                    'dimension_codes' => 'One or more dimension codes are invalid.',
                ]);
            }
        }

        $option->dimensionCodes()->delete();

        foreach (array_values($normalized) as $index => $code) {
            $option->dimensionCodes()->create([
                'dimension_code' => $code,
                'display_order' => $index + 1,
            ]);
        }
    }
}
