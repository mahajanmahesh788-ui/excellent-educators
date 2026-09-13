<?php

namespace App\Models;

use App\Enums\TeacherBreakType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherBreak extends Model
{
    use HasUlids;

    protected $fillable = [
        'teacher_id',
        'type',
        'start_time',
        'end_time',
        'is_recurring',
    ];

    protected function casts(): array
    {
        return [
            'type' => TeacherBreakType::class,
            'is_recurring' => 'boolean',
        ];
    }

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(TeacherProfile::class, 'teacher_id');
    }
}
