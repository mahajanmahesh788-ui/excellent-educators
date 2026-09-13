<?php

namespace App\Models;

use App\Enums\ProfileStatus;
use App\Enums\TeacherWorkType;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class TeacherProfile extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'user_id',
        'employee_code',
        'full_name',
        'phone',
        'whatsapp_number',
        'address',
        'status',
        'work_type',
    ];

    protected function casts(): array
    {
        return [
            'status' => ProfileStatus::class,
            'work_type' => TeacherWorkType::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function batchAssignments(): HasMany
    {
        return $this->hasMany(BatchTeacher::class, 'teacher_id');
    }

    public function activeBatchAssignments(): HasMany
    {
        return $this->hasMany(BatchTeacher::class, 'teacher_id')->whereNull('ended_at');
    }

    public function masterTeacherAssignments(): HasMany
    {
        return $this->hasMany(MasterTeacherAssignment::class, 'teacher_id');
    }

    public function academicLevels(): BelongsToMany
    {
        return $this->belongsToMany(AcademicLevel::class, 'academic_level_teachers', 'teacher_id', 'level_id')
            ->withTimestamps();
    }

    public function activeMasterTeacherAssignments(): HasMany
    {
        return $this->hasMany(MasterTeacherAssignment::class, 'teacher_id')->whereNull('ended_at');
    }

    public function hasActiveAssignments(): bool
    {
        return $this->activeBatchAssignments()->exists()
            || $this->activeMasterTeacherAssignments()->exists()
            || $this->academicLevels()->exists();
    }

    /**
     * @return \Illuminate\Support\Collection<int, string>
     */
    public function rosterStudentIds()
    {
        $levelIds = $this->academicLevels()->pluck('academic_levels.id');

        $fromLevel = $levelIds->isEmpty()
            ? collect()
            : StudentProfile::query()->whereIn('level_id', $levelIds)->pluck('id');

        $fromBatch = $levelIds->isEmpty()
            ? collect()
            : BatchStudent::query()
                ->whereNull('left_at')
                ->where('status', ProfileStatus::Active->value)
                ->whereHas('batch', fn ($query) => $query->whereIn('level_id', $levelIds))
                ->pluck('student_id');

        return $this->activeMasterTeacherAssignments()
            ->pluck('student_id')
            ->concat($fromLevel)
            ->concat($fromBatch)
            ->unique()
            ->values();
    }

    public function canAccessStudent(StudentProfile|string $student): bool
    {
        $id = $student instanceof StudentProfile ? $student->id : $student;
        if ($this->activeMasterTeacherAssignments()->where('student_id', $id)->exists()) {
            return true;
        }

        $profile = $student instanceof StudentProfile
            ? $student->loadMissing('activeEnrollment.batch')
            : StudentProfile::query()->with('activeEnrollment.batch')->find($id);

        if ($profile === null) {
            return false;
        }

        $levelIds = $this->academicLevels()->pluck('academic_levels.id');
        if ($profile->level_id && $levelIds->contains($profile->level_id)) {
            return true;
        }

        $batchLevelId = $profile->activeEnrollment?->batch?->level_id;

        return $batchLevelId !== null && $levelIds->contains($batchLevelId);
    }

    public function breaks(): HasMany
    {
        return $this->hasMany(TeacherBreak::class, 'teacher_id');
    }

    public function leaves(): HasMany
    {
        return $this->hasMany(TeacherLeave::class, 'teacher_id');
    }

    public function weeklyOffs(): HasMany
    {
        return $this->hasMany(TeacherWeeklyOff::class, 'teacher_id');
    }

    public function availabilityRules(): HasMany
    {
        return $this->hasMany(TeacherAvailabilityRule::class, 'teacher_id');
    }

    public function availabilityOverrides(): HasMany
    {
        return $this->hasMany(TeacherAvailabilityOverride::class, 'teacher_id');
    }

    public function sessionBookings(): HasMany
    {
        return $this->hasMany(SessionBooking::class, 'teacher_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', ProfileStatus::Active->value);
    }
}
