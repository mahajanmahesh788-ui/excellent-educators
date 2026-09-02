<?php

namespace App\Models;

use App\Enums\AdminRequestRequesterType;
use App\Enums\AdminRequestStatus;
use App\Enums\AdminRequestType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AdminRequest extends Model
{
    use HasUlids;

    protected $fillable = [
        'user_id',
        'requester_type',
        'request_type',
        'subtitle',
        'description',
        'student_id',
        'batch_id',
        'status',
        'resolved_at',
        'resolved_by_id',
    ];

    protected function casts(): array
    {
        return [
            'requester_type' => AdminRequestRequesterType::class,
            'request_type' => AdminRequestType::class,
            'status' => AdminRequestStatus::class,
            'resolved_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function resolvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by_id');
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function batch(): BelongsTo
    {
        return $this->belongsTo(Batch::class, 'batch_id');
    }

    public function isPending(): bool
    {
        return $this->status === AdminRequestStatus::Pending;
    }
}
