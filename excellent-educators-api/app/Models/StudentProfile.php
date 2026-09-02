<?php

namespace App\Models;

use App\Enums\ProfileStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class StudentProfile extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'user_id',
        'student_code',
        'career_compass_level_id',
        'class_grade',
        'full_name',
        'phone',
        'whatsapp_number',
        'guardian_name',
        'guardian_phone',
        'status',
        'id_academic_year',
    ];

    protected function casts(): array
    {
        return [
            'class_grade' => 'integer',
            'id_academic_year' => 'integer',
            'status' => ProfileStatus::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function careerCompassLevel(): BelongsTo
    {
        return $this->belongsTo(CareerCompassLevel::class);
    }

    public function enrollments(): HasMany
    {
        return $this->hasMany(BatchStudent::class, 'student_id');
    }

    public function activeEnrollment(): HasOne
    {
        return $this->hasOne(BatchStudent::class, 'student_id')
            ->whereNull('left_at')
            ->where('status', ProfileStatus::Active->value);
    }

    public function masterTeacherAssignments(): HasMany
    {
        return $this->hasMany(MasterTeacherAssignment::class, 'student_id');
    }

    public function activeMasterTeacherAssignment(): HasOne
    {
        return $this->hasOne(MasterTeacherAssignment::class, 'student_id')->whereNull('ended_at');
    }

    public function aptitudeAssessmentResults(): HasMany
    {
        return $this->hasMany(AptitudeAssessmentResult::class, 'student_id');
    }

    public function latestAptitudeAssessmentResult(): HasOne
    {
        return $this->hasOne(AptitudeAssessmentResult::class, 'student_id')->latestOfMany('calculated_at');
    }

    public function monthlyFeedbacks(): HasMany
    {
        return $this->hasMany(MonthlyFeedback::class, 'student_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', ProfileStatus::Active->value);
    }
}
