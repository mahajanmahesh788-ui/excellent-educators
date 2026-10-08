<?php

namespace App\Models;

use App\Enums\InterestOptionSource;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InterestOption extends Model
{
    use HasUlids;

    protected $fillable = [
        'interest_question_id',
        'option_text',
        'normalized_key',
        'source',
        'display_order',
        'is_active',
        'usage_count',
    ];

    protected function casts(): array
    {
        return [
            'source' => InterestOptionSource::class,
            'display_order' => 'integer',
            'is_active' => 'boolean',
            'usage_count' => 'integer',
        ];
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(InterestQuestion::class, 'interest_question_id');
    }
}
