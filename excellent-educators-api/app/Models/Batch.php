<?php

namespace App\Models;

use App\Enums\BatchStatus;
use App\Enums\ProfileStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Batch extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'level_id',
        'career_compass_level_id',
        'name',
        'academic_year',
        'year',
        'month',
        'enrolled_watermark',
        'starts_on',
        'ends_on',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'academic_year' => 'integer',
            'year' => 'integer',
            'month' => 'integer',
            'enrolled_watermark' => 'integer',
            'starts_on' => 'date',
            'ends_on' => 'date',
            'status' => BatchStatus::class,
        ];
    }

    public function level(): BelongsTo
    {
        return $this->belongsTo(AcademicLevel::class, 'level_id');
    }

    public function careerCompassLevel(): BelongsTo
    {
        return $this->belongsTo(CareerCompassLevel::class);
    }

    public function enrollments(): HasMany
    {
        return $this->hasMany(BatchStudent::class);
    }

    public function activeEnrollments(): HasMany
    {
        return $this->hasMany(BatchStudent::class)
            ->whereNull('left_at')
            ->where('status', ProfileStatus::Active->value);
    }

    public function teacherAssignments(): HasMany
    {
        return $this->hasMany(BatchTeacher::class);
    }

    public function activeTeacherAssignment(): HasOne
    {
        return $this->hasOne(BatchTeacher::class)->whereNull('ended_at');
    }

    public function activeStudentCount(): int
    {
        return $this->enrollments()
            ->whereNull('left_at')
            ->where('status', ProfileStatus::Active->value)
            ->count();
    }
}
