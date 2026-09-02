<?php

namespace App\Http\Resources\Api\V1;

use App\Models\LoginPageContent;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin LoginPageContent */
class LoginPageContentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'tagline' => $this->tagline,
            'headline' => $this->headline,
            'description' => $this->description,
            'pillars' => $this->pillars,
            'mission_quote' => $this->mission_quote,
            'form_title' => $this->form_title,
            'form_subtitle' => $this->form_subtitle,
            'forgot_form_title' => $this->forgot_form_title,
            'forgot_form_subtitle' => $this->forgot_form_subtitle,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
