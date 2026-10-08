<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ParentResponseAnswer extends Model
{
    use HasUlids;

    protected $fillable = [
        'parent_response_id',
        'parent_question_id',
        'text_answer',
        'parent_option_id',
    ];

    public function response(): BelongsTo
    {
        return $this->belongsTo(ParentResponse::class, 'parent_response_id');
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(ParentQuestion::class, 'parent_question_id');
    }

    public function option(): BelongsTo
    {
        return $this->belongsTo(ParentOption::class, 'parent_option_id');
    }
}
