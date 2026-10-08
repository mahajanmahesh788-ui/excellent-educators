<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class InterestResponseAnswer extends Model
{
    use HasUlids;

    protected $fillable = [
        'interest_response_id',
        'interest_question_id',
        'other_text',
    ];

    public function response(): BelongsTo
    {
        return $this->belongsTo(InterestResponse::class, 'interest_response_id');
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(InterestQuestion::class, 'interest_question_id');
    }

    public function options(): BelongsToMany
    {
        return $this->belongsToMany(
            InterestOption::class,
            'interest_response_answer_options',
            'interest_response_answer_id',
            'interest_option_id',
        )->withTimestamps();
    }
}
