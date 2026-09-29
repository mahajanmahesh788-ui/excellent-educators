<?php

namespace App\Models;

use App\Enums\PaymentMode;
use App\Enums\PaymentTransactionStatus;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StudentPayment extends Model
{
    use HasUlids;

    protected $fillable = [
        'student_id',
        'payment_plan_id',
        'amount',
        'payment_mode',
        'payment_date',
        'transaction_id',
        'reference_number',
        'status',
        'notes',
        'receipt_path',
        'gateway',
        'gateway_order_id',
        'gateway_payment_id',
        'gateway_payload',
        'applies_to_dues',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'payment_mode' => PaymentMode::class,
            'status' => PaymentTransactionStatus::class,
            'amount' => 'decimal:2',
            'payment_date' => 'date',
            'gateway_payload' => 'array',
            'applies_to_dues' => 'boolean',
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

    public function createdByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
