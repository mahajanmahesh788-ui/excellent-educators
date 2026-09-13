<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class AcademicLevel extends Model
{
    use HasUlids, SoftDeletes;

    protected $table = 'academic_levels';

    protected $fillable = [
        'name',
        'academic_year',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'academic_year' => 'integer',
        ];
    }

    public function batches(): HasMany
    {
        return $this->hasMany(Batch::class, 'level_id')->orderBy('created_at');
    }

    public function students(): HasMany
    {
        return $this->hasMany(StudentProfile::class, 'level_id');
    }

    public function masterTeachers(): BelongsToMany
    {
        return $this->belongsToMany(TeacherProfile::class, 'academic_level_teachers', 'level_id', 'teacher_id')
            ->withTimestamps();
    }

    public function weeklyLearnings(): HasMany
    {
        return $this->hasMany(WeeklyLearning::class, 'level_id')->orderBy('week_number');
    }
}
