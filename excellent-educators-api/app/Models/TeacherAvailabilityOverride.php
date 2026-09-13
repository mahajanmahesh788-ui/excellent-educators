<?php

namespace App\Models;

use App\Enums\TeacherAvailabilityOverrideType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherAvailabilityOverride extends Model
{
    use HasUlids;

    protected $fillable = [
        'teacher_id',
        'date',
        'type',
        'start_time',
        'end_time',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'type' => TeacherAvailabilityOverrideType::class,
        ];
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'teacher_id');
    }
}
