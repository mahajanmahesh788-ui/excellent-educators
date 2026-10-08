<?php

namespace App\Models;

use App\Enums\OnboardingQuestionType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ParentQuestion extends Model
{
    use HasUlids;

    protected $fillable = [
        'question_text',
        'question_type',
        'display_order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'question_type' => OnboardingQuestionType::class,
            'display_order' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function options(): HasMany
    {
        return $this->hasMany(ParentOption::class)->orderBy('display_order');
    }

    public function isText(): bool
    {
        return $this->question_type === OnboardingQuestionType::Text;
    }

    public function isOptions(): bool
    {
        return $this->question_type === OnboardingQuestionType::Options;
    }
}
