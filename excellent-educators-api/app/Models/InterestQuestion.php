<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class InterestQuestion extends Model
{
    use HasUlids;

    protected $fillable = [
        'question_text',
        'allow_other',
        'max_selections',
        'display_order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'allow_other' => 'boolean',
            'max_selections' => 'integer',
            'display_order' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function options(): HasMany
    {
        return $this->hasMany(InterestOption::class)->orderBy('display_order');
    }

    public function activeOptions(): HasMany
    {
        return $this->options()->where('is_active', true);
    }
}
