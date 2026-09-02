<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AssessmentVersion extends Model
{
    use HasUlids;

    public $timestamps = false;

    protected $fillable = [
        'assessment_id',
        'version',
        'title',
        'description',
        'max_score',
        'revised_by',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'max_score' => 'decimal:2',
            'version' => 'integer',
            'created_at' => 'datetime',
        ];
    }

    public function assessment(): BelongsTo
    {
        return $this->belongsTo(Assessment::class);
    }

    public function reviser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'revised_by');
    }
}
