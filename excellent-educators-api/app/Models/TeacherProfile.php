<?php

namespace App\Models;

use App\Enums\ProfileStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
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
        'status',
    ];

    protected function casts(): array
    {
        return [
            'status' => ProfileStatus::class,
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

    public function activeMasterTeacherAssignments(): HasMany
    {
        return $this->hasMany(MasterTeacherAssignment::class, 'teacher_id')->whereNull('ended_at');
    }

    public function hasActiveAssignments(): bool
    {
        return $this->activeBatchAssignments()->exists()
            || $this->activeMasterTeacherAssignments()->exists();
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', ProfileStatus::Active->value);
    }
}
