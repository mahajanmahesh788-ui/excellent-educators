<?php

namespace App\Http\Resources\Api\V1;

use App\Models\CareerCompassLevel;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin CareerCompassLevel
 */
class CareerCompassLevelResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'name' => $this->name,
            'class_from' => $this->class_from,
            'class_to' => $this->class_to,
        ];
    }
}
