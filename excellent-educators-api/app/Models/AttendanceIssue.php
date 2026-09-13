<?php

namespace App\Models;

use App\Enums\AttendanceDecision;
use App\Enums\AttendanceIssueType;
use App\Enums\AttendanceVerificationStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceIssue extends Model
{
    use HasUlids;

    protected $fillable = [
        'booking_id',
        'reporter_user_id',
        'reporter_role',
        'issue_type',
        'message',
        'verification_status',
        'admin_decision',
        'admin_notes',
        'verified_by',
        'verified_at',
    ];

    protected function casts(): array
    {
        return [
            'issue_type' => AttendanceIssueType::class,
            'verification_status' => AttendanceVerificationStatus::class,
            'admin_decision' => AttendanceDecision::class,
            'verified_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(SessionBooking::class, 'booking_id');
    }

    public function reporter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reporter_user_id');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function isPending(): bool
    {
        return $this->verification_status === AttendanceVerificationStatus::Pending;
    }
}
