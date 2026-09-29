<?php

namespace App\Models;

use App\Enums\PaymentMode;
use App\Enums\PaymentPlanStatus;
use App\Enums\PaymentPlanType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class StudentPaymentPlan extends Model
{
    use HasUlids;

    protected $fillable = [
        'student_id',
        'payment_type',
        'total_amount',
        'paid_amount',
        'pending_amount',
        'advance_amount',
        'dead_amount',
        'installment_amount',
        'due_day',
        'start_date',
        'next_due_date',
        'next_due_amount',
        'overdue_amount',
        'last_payment_date',
        'preferred_mode',
        'status',
        'is_active',
        'withdrawn_at',
        'student_name_snapshot',
        'student_code_snapshot',
        'created_by',
        'updated_by',
    ];

    protected function casts(): array
    {
        return [
            'payment_type' => PaymentPlanType::class,
            'preferred_mode' => PaymentMode::class,
            'status' => PaymentPlanStatus::class,
            'total_amount' => 'decimal:2',
            'paid_amount' => 'decimal:2',
            'pending_amount' => 'decimal:2',
            'advance_amount' => 'decimal:2',
            'dead_amount' => 'decimal:2',
            'installment_amount' => 'decimal:2',
            'next_due_amount' => 'decimal:2',
            'overdue_amount' => 'decimal:2',
            'due_day' => 'integer',
            'start_date' => 'date',
            'next_due_date' => 'date',
            'last_payment_date' => 'date',
            'withdrawn_at' => 'datetime',
            'is_active' => 'boolean',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(StudentProfile::class, 'student_id');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(StudentPayment::class, 'payment_plan_id');
    }

    public function createdByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updatedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
