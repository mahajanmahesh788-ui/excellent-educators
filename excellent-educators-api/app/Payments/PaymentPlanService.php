<?php

namespace App\Payments;

use App\Enums\PaymentMode;
use App\Enums\PaymentPlanStatus;
use App\Enums\PaymentPlanType;
use App\Enums\PaymentTransactionStatus;
use App\Exceptions\ApiException;
use App\Models\StudentPayment;
use App\Models\StudentPaymentPlan;
use App\Models\StudentPaymentPlanAudit;
use App\Models\StudentProfile;
use App\Support\AppClock;
use App\Support\ErrorCode;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class PaymentPlanService
{
    public function __construct(private readonly PaymentSettings $settings) {}

    /**
     * @param  array{
     *     payment_type: string,
     *     preferred_mode?: string|null,
     *     total_amount?: float|int|null,
     *     initial_amount?: float|int|null,
     *     payment_amount?: float|int|null,
     *     payment_date?: string|null,
     *     transaction_id?: string|null,
     *     reference_number?: string|null,
     *     notes?: string|null,
     *     due_day?: int|null,
     *     start_date?: string|null,
     * }  $input
     */
    public function createForStudent(StudentProfile $student, array $input, ?string $actorId = null): StudentPaymentPlan
    {
        $type = PaymentPlanType::from($input['payment_type']);
        if ($type === PaymentPlanType::Partial && ! $this->settings->partialEnabled()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Partial payment is disabled in settings.', 422);
        }

        $mode = isset($input['preferred_mode'])
            ? PaymentMode::from($input['preferred_mode'])
            : PaymentMode::Offline;
        $this->assertModeEnabled($mode);

        $defaults = $type === PaymentPlanType::Full
            ? $this->settings->fullAmount()
            : $this->settings->partialTotal();
        $total = round((float) ($input['total_amount'] ?? $defaults), 2);
        if ($total <= 0) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Total amount must be greater than zero.', 422);
        }

        $dueDay = $type === PaymentPlanType::Partial
            ? (int) ($input['due_day'] ?? $this->settings->dueDay())
            : null;
        $startDate = isset($input['start_date'])
            ? Carbon::parse($input['start_date'])->startOfDay()
            : AppClock::now()->startOfDay();

        $initial = round((float) ($input['initial_amount'] ?? $input['payment_amount'] ?? 0), 2);
        if ($initial < 0) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Payment amount cannot be negative.', 422);
        }
        if ($initial > $total) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Paid amount cannot exceed the total payable amount.', 422);
        }

        return DB::transaction(function () use ($student, $type, $mode, $total, $dueDay, $startDate, $initial, $input, $actorId): StudentPaymentPlan {
            StudentPaymentPlan::query()
                ->where('student_id', $student->id)
                ->where('is_active', true)
                ->update(['is_active' => false, 'updated_by' => $actorId]);

            $plan = StudentPaymentPlan::query()->create([
                'student_id' => $student->id,
                'payment_type' => $type,
                'total_amount' => $total,
                'paid_amount' => 0,
                'pending_amount' => $total,
                'advance_amount' => 0,
                'installment_amount' => null,
                'due_day' => $dueDay,
                'start_date' => $startDate->toDateString(),
                'next_due_date' => null,
                'next_due_amount' => null,
                'overdue_amount' => 0,
                'preferred_mode' => $mode,
                'status' => PaymentPlanStatus::Pending,
                'is_active' => true,
                'created_by' => $actorId,
                'updated_by' => $actorId,
            ]);

            if ($initial > 0) {
                $this->recordSuccessfulPayment($plan, [
                    'amount' => $initial,
                    'payment_mode' => $mode->value,
                    'payment_date' => $input['payment_date'] ?? null,
                    'notes' => $input['notes'] ?? 'Initial payment',
                ], $actorId);
            } else {
                $this->recalculate($plan->fresh());
            }

            return $plan->fresh(['payments']) ?? $plan;
        });
    }

    /**
     * @param  array{
     *     amount: float|int|string,
     *     payment_mode: string,
     *     payment_date?: string|null,
     *     notes?: string|null,
     *     receipt_path?: string|null,
     *     gateway?: string|null,
     *     gateway_order_id?: string|null,
     *     gateway_payment_id?: string|null,
     *     gateway_payload?: array<string, mixed>|null,
     * }  $input
     */
    public function recordSuccessfulPayment(StudentPaymentPlan $plan, array $input, ?string $actorId = null): StudentPayment
    {
        $amount = round((float) $input['amount'], 2);
        if ($amount <= 0) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Payment amount must be greater than zero.', 422);
        }

        $mode = PaymentMode::from($input['payment_mode']);
        $this->assertModeEnabled($mode);

        if (! empty($input['gateway_order_id'])) {
            $existing = StudentPayment::query()
                ->where('gateway_order_id', $input['gateway_order_id'])
                ->first();
            if ($existing !== null) {
                return $existing;
            }
        }

        $paymentDate = ! empty($input['payment_date'])
            ? Carbon::parse($input['payment_date'])->toDateString()
            : AppClock::now()->toDateString();

        return DB::transaction(function () use ($plan, $input, $amount, $mode, $actorId, $paymentDate): StudentPayment {
            $plan = StudentPaymentPlan::query()->lockForUpdate()->findOrFail($plan->id);
            $pending = round((float) $plan->pending_amount, 2);
            if ($amount > $pending + 0.001) {
                $left = rtrim(rtrim(number_format($pending, 2, '.', ''), '0'), '.');
                throw new ApiException(
                    ErrorCode::VALIDATION_ERROR,
                    "Only ₹{$left} left. Amount cannot exceed the pending amount.",
                    422,
                );
            }

            $payment = StudentPayment::query()->create([
                'student_id' => $plan->student_id,
                'payment_plan_id' => $plan->id,
                'amount' => $amount,
                'payment_mode' => $mode,
                'payment_date' => $paymentDate,
                'status' => PaymentTransactionStatus::Successful,
                'notes' => $input['notes'] ?? null,
                'receipt_path' => $input['receipt_path'] ?? null,
                'gateway' => $input['gateway'] ?? null,
                'gateway_order_id' => $input['gateway_order_id'] ?? null,
                'gateway_payment_id' => $input['gateway_payment_id'] ?? null,
                'gateway_payload' => $input['gateway_payload'] ?? null,
                'applies_to_dues' => true,
                'created_by' => $actorId,
            ]);

            $this->recalculate($plan->fresh() ?? $plan, $actorId);

            return $payment;
        });
    }

    public function recalculate(StudentPaymentPlan $plan, ?string $actorId = null): StudentPaymentPlan
    {
        $plan = StudentPaymentPlan::query()->lockForUpdate()->findOrFail($plan->id);
        $paid = (float) $plan->payments()
            ->where('status', PaymentTransactionStatus::Successful->value)
            ->sum('amount');
        $total = (float) $plan->total_amount;
        $pending = max(0, round($total - $paid, 2));
        // Overpayments are rejected at record time; advance is never allowed.
        $advance = 0.0;

        $lastPayment = $plan->payments()
            ->where('status', PaymentTransactionStatus::Successful->value)
            ->orderByDesc('payment_date')
            ->orderByDesc('created_at')
            ->first();

        $nextDueDate = null;
        $nextDueAmount = null;
        $overdueAmount = 0.0;
        $status = PaymentPlanStatus::Pending;

        if ($pending <= 0) {
            $status = PaymentPlanStatus::Paid;
            $pending = 0;
        } elseif ($plan->payment_type === PaymentPlanType::Partial) {
            [$nextDueDate, $nextDueAmount, $overdueAmount, $status] = $this->partialSchedule(
                $plan,
                $paid,
                $pending,
                $lastPayment?->payment_date,
            );
        } else {
            $status = $paid > 0 ? PaymentPlanStatus::Partial : PaymentPlanStatus::Pending;
            $nextDueAmount = $pending;
            $nextDueDate = $plan->start_date?->toDateString() ?? AppClock::now()->toDateString();
            if ($nextDueDate !== null && Carbon::parse($nextDueDate)->lt(AppClock::now()->startOfDay()->subDays($this->settings->graceDays()))) {
                $status = PaymentPlanStatus::Overdue;
                $overdueAmount = $pending;
            }
        }

        $plan->fill([
            'paid_amount' => round($paid, 2),
            'pending_amount' => $pending,
            'advance_amount' => $advance,
            'last_payment_date' => $lastPayment?->payment_date?->toDateString(),
            'next_due_date' => $nextDueDate,
            'next_due_amount' => $nextDueAmount,
            'overdue_amount' => round($overdueAmount, 2),
            'status' => $status,
            'updated_by' => $actorId ?? $plan->updated_by,
        ]);
        $plan->save();

        return $plan->fresh() ?? $plan;
    }

    /**
     * @return array{0: ?string, 1: ?float, 2: float, 3: PaymentPlanStatus}
     */
    private function partialSchedule(
        StudentPaymentPlan $plan,
        float $paid,
        float $pending,
        mixed $lastPaymentDate,
    ): array {
        $dueDay = (int) ($plan->due_day ?: $this->settings->dueDay());
        $grace = $this->settings->graceDays();
        $today = AppClock::now()->startOfDay();

        $anchor = $lastPaymentDate
            ? Carbon::parse($lastPaymentDate)->startOfDay()
            : ($plan->start_date?->copy()->startOfDay() ?? $today->copy());

        // Next due date after last payment / start (same day-of-month each cycle).
        $candidate = $anchor->copy()->day(min($dueDay, $anchor->daysInMonth));
        if ($candidate->lte($anchor)) {
            $candidate = $candidate->addMonthNoOverflow()->day(min($dueDay, $candidate->copy()->addMonthNoOverflow()->daysInMonth));
        }

        $nextDueAmount = round($pending, 2);
        $nextDueDate = $candidate->toDateString();
        $overdue = 0.0;
        $status = $paid > 0 ? PaymentPlanStatus::Partial : PaymentPlanStatus::Pending;

        $graceDeadline = $candidate->copy()->addDays($grace);
        if ($pending > 0 && $graceDeadline->lt($today)) {
            $status = PaymentPlanStatus::Overdue;
            $overdue = $pending;
            $overdueDate = $today->copy()->day(min($dueDay, $today->daysInMonth));
            if ($overdueDate->gt($today)) {
                $overdueDate = $overdueDate->subMonthNoOverflow()->day(min($dueDay, $overdueDate->copy()->subMonthNoOverflow()->daysInMonth));
            }
            $nextDueDate = $overdueDate->toDateString();
        }

        return [$nextDueDate, $nextDueAmount, round($overdue, 2), $status];
    }

    /**
     * @param  array{
     *     payment_type: string,
     *     total_amount?: float|int|null,
     *     due_day?: int|null,
     *     preferred_mode?: string|null,
     *     reason?: string|null,
     * }  $input
     */
    public function changePlan(StudentPaymentPlan $plan, array $input, ?string $actorId = null): StudentPaymentPlan
    {
        $newType = PaymentPlanType::from($input['payment_type']);

        // Existing plans keep their locked total unless admin explicitly sends a new amount.
        // Admin Settings amounts apply only when creating NEW plans — never retroactively.
        $newTotal = array_key_exists('total_amount', $input) && $input['total_amount'] !== null
            ? round((float) $input['total_amount'], 2)
            : round((float) $plan->total_amount, 2);

        if ($newTotal <= 0) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Total amount must be greater than zero.', 422);
        }

        return DB::transaction(function () use ($plan, $newType, $newTotal, $input, $actorId): StudentPaymentPlan {
            $plan = StudentPaymentPlan::query()->lockForUpdate()->findOrFail($plan->id);

            StudentPaymentPlanAudit::query()->create([
                'student_id' => $plan->student_id,
                'payment_plan_id' => $plan->id,
                'previous_plan' => $plan->payment_type->value,
                'new_plan' => $newType->value,
                'previous_amount' => $plan->total_amount,
                'new_amount' => $newTotal,
                'reason' => $input['reason'] ?? null,
                'snapshot' => $plan->toArray(),
                'changed_by' => $actorId,
                'changed_at' => AppClock::now(),
            ]);

            $plan->fill([
                'payment_type' => $newType,
                'total_amount' => $newTotal,
                'installment_amount' => null,
                'due_day' => $newType === PaymentPlanType::Partial
                    ? (int) ($input['due_day'] ?? $plan->due_day ?? $this->settings->dueDay())
                    : null,
                'preferred_mode' => isset($input['preferred_mode'])
                    ? PaymentMode::from($input['preferred_mode'])
                    : $plan->preferred_mode,
                'updated_by' => $actorId,
            ]);
            $plan->save();

            return $this->recalculate($plan, $actorId);
        });
    }

    public function activePlanFor(StudentProfile $student): ?StudentPaymentPlan
    {
        return StudentPaymentPlan::query()
            ->where('student_id', $student->id)
            ->where('is_active', true)
            ->with(['payments' => fn ($q) => $q->orderByDesc('payment_date')->orderByDesc('created_at')])
            ->first();
    }

    private function assertModeEnabled(PaymentMode $mode): void
    {
        if ($mode === PaymentMode::Online && ! $this->settings->onlineEnabled()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Online payment is disabled.', 422);
        }
        if ($mode === PaymentMode::Offline && ! $this->settings->offlineEnabled()) {
            throw new ApiException(ErrorCode::VALIDATION_ERROR, 'Offline payment is disabled.', 422);
        }
    }
}
