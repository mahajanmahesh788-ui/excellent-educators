<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AssessmentScore extends Model
{
    use HasUlids;

    protected $fillable = [
        'assessment_id',
        'student_id',
        'version',
        'score',
        'notes',
        'scored_by',
        'scored_at',
    ];

    protected function casts(): array
    {
        return [
            'version' => 'integer',
            'score' => 'decimal:2',
            'scored_at' => 'datetime',
        ];
    }

    public function assessment(): BelongsTo
    {
        return $this->belongsTo(Assessment::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function scorer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'scored_by');
    }
}
