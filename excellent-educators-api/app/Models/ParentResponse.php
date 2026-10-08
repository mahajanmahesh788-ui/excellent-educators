<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ParentResponse extends Model
{
    use HasUlids;

    protected $fillable = [
        'student_id',
        'completed_at',
        'skipped_at',
    ];

    protected function casts(): array
    {
        return [
            'completed_at' => 'datetime',
            'skipped_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function answers(): HasMany
    {
        return $this->hasMany(ParentResponseAnswer::class);
    }

    public function isSkipped(): bool
    {
        return $this->skipped_at !== null;
    }

    public function isCompleted(): bool
    {
        return $this->completed_at !== null;
    }
}
