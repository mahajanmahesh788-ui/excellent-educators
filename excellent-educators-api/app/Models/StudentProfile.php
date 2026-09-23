<?php

namespace App\Models;

use App\Enums\Gender;
use App\Enums\ProfileStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class StudentProfile extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'user_id',
        'student_code',
        'level_id',
        'master_classes_per_month',
        'class_grade',
        'full_name',
        'gender',
        'phone',
        'whatsapp_number',
        'address',
        'guardian_name',
        'guardian_phone',
        'status',
        'id_academic_year',
    ];

    protected function casts(): array
    {
        return [
            'class_grade' => 'integer',
            'gender' => Gender::class,
            'master_classes_per_month' => 'integer',
            'id_academic_year' => 'integer',
            'status' => ProfileStatus::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function academicLevel(): BelongsTo
    {
        return $this->belongsTo(AcademicLevel::class, 'level_id');
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

    public function sessionBookings(): HasMany
    {
        return $this->hasMany(SessionBooking::class, 'student_id');
    }

    public function levelJourneys(): HasMany
    {
        return $this->hasMany(StudentLevelJourney::class, 'student_id');
    }

    public function currentLevelJourney(): HasOne
    {
        return $this->hasOne(StudentLevelJourney::class, 'student_id')->whereNull('ended_at');
    }

    public function weeklyAssignmentAttempts(): HasMany
    {
        return $this->hasMany(WeeklyAssignmentAttempt::class, 'student_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', ProfileStatus::Active->value);
    }

    /**
     * @param  Collection<int, self>|iterable<self>  $students
     */
    public static function attachOverallAverages(iterable $students): void
    {
        $profiles = Collection::make($students)->filter()->unique('id')->values();
        if ($profiles->isEmpty()) {
            return;
        }

        $averages = DB::table('monthly_feedback_items')
            ->join('monthly_feedbacks', 'monthly_feedbacks.id', '=', 'monthly_feedback_items.monthly_feedback_id')
            ->whereIn('monthly_feedbacks.student_id', $profiles->pluck('id'))
            ->groupBy('monthly_feedbacks.student_id')
            ->selectRaw('monthly_feedbacks.student_id, avg(monthly_feedback_items.rating) as avg_rating')
            ->pluck('avg_rating', 'student_id');

        foreach ($profiles as $student) {
            $student->feedback_overall_average = $averages[$student->id] ?? null;
        }
    }
}
