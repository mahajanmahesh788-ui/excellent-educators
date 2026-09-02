<?php

namespace App\Models;

use App\Enums\AssessmentStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Assessment extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'batch_id',
        'created_by',
        'title',
        'description',
        'max_score',
        'version',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'max_score' => 'decimal:2',
            'version' => 'integer',
            'status' => AssessmentStatus::class,
        ];
    }

    public function batch(): BelongsTo
    {
        return $this->belongsTo(Batch::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function versions(): HasMany
    {
        return $this->hasMany(AssessmentVersion::class);
    }

    public function scores(): HasMany
    {
        return $this->hasMany(AssessmentScore::class);
    }

    public function currentScores(): HasMany
    {
        return $this->hasMany(AssessmentScore::class)
            ->where('version', $this->version);
    }
}
