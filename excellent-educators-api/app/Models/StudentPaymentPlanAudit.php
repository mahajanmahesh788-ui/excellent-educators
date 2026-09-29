<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StudentPaymentPlanAudit extends Model
{
    use HasUlids;

    protected $fillable = [
        'student_id',
        'payment_plan_id',
        'previous_plan',
        'new_plan',
        'previous_amount',
        'new_amount',
        'reason',
        'snapshot',
        'changed_by',
        'changed_at',
    ];

    protected function casts(): array
    {
        return [
            'previous_amount' => 'decimal:2',
            'new_amount' => 'decimal:2',
            'snapshot' => 'array',
            'changed_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(StudentPaymentPlan::class, 'payment_plan_id');
    }

    public function changedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by');
    }
}
