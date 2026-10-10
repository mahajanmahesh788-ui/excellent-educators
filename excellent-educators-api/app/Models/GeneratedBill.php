<?php

namespace App\Models;

use App\Enums\Gender;
use App\Enums\PaymentMode;
use App\Enums\PaymentPlanType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GeneratedBill extends Model
{
    use HasUlids;

    protected $fillable = [
        'bill_number',
        'full_name',
        'email',
        'phone',
        'whatsapp_number',
        'address',
        'class_grade',
        'gender',
        'guardian_name',
        'guardian_phone',
        'payment_type',
        'payment_mode',
        'total_amount',
        'paid_amount',
        'notes',
        'bill_date',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'gender' => Gender::class,
            'payment_type' => PaymentPlanType::class,
            'payment_mode' => PaymentMode::class,
            'class_grade' => 'integer',
            'total_amount' => 'decimal:2',
            'paid_amount' => 'decimal:2',
            'bill_date' => 'date',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function pendingAmount(): float
    {
        return max(0, (float) $this->total_amount - (float) $this->paid_amount);
    }
}
