<?php

namespace App\Http\Resources\Api\V1;

use App\Models\Dimension;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Dimension
 */
class FeedbackCatalogResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code?->value ?? $this->code,
            'name' => $this->name,
            'display_order' => $this->display_order,
        ];
    }
}
