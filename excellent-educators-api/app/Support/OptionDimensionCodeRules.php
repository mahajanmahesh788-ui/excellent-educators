<?php

namespace App\Support;

use App\Enums\DimensionCode;
use Illuminate\Validation\Rule;

abstract class OptionDimensionCodeRules
{
    /**
     * @return array<string, mixed>
     */
    public static function forField(string $field = 'dimension_codes'): array
    {
        return [
            $field => ['required', 'array', 'min:1', 'max:3'],
            "{$field}.*" => ['required', Rule::enum(DimensionCode::class), 'distinct'],
        ];
    }
}
