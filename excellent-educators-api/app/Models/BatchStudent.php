<?php

namespace App\Models;

use App\Enums\ProfileStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BatchStudent extends Model
{
    use HasUlids;

    protected $fillable = [
        'batch_id',
        'student_id',
        'enrolled_by',
        'status',
        'enrolled_at',
        'left_at',
    ];

    protected function casts(): array
    {
        return [
            'status' => ProfileStatus::class,
            'enrolled_at' => 'datetime',
            'left_at' => 'datetime',
        ];
    }

    public function batch(): BelongsTo
    {
        return $this->belongsTo(Batch::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function enrolledBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'enrolled_by');
    }

    public function isActive(): bool
    {
        return $this->left_at === null && $this->status === ProfileStatus::Active;
    }
}
