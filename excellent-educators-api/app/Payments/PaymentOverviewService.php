<?php

namespace App\Payments;

use App\Enums\PaymentPlanStatus;
use App\Enums\PaymentTransactionStatus;
use App\Models\StudentPayment;
use App\Models\StudentPaymentPlan;
use App\Support\AppClock;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

class PaymentOverviewService
{
    /**
     * @return array<string, float|int>
     */
    public function summaryCards(?string $createdByUserId = null): array
    {
        $monthStart = AppClock::now()->copy()->startOfMonth();
        $monthEnd = AppClock::now()->copy()->endOfMonth();

        $active = StudentPaymentPlan::query()
            ->where('is_active', true)
            ->where('status', '!=', PaymentPlanStatus::Withdrawn->value)
            ->when(
                $createdByUserId !== null,
                fn (Builder $q) => $q->whereHas(
                    'student',
                    fn (Builder $s) => $s->where('created_by_user_id', $createdByUserId),
                ),
            );

        $ownedPayments = StudentPayment::query()
            ->when(
                $createdByUserId !== null,
                fn (Builder $q) => $q->whereHas(
                    'student',
                    fn (Builder $s) => $s->where('created_by_user_id', $createdByUserId),
                ),
            );

        return [
            'all_pending' => (clone $active)->where('pending_amount', '>', 0)->count(),
            'due_this_month' => (clone $active)
                ->where('pending_amount', '>', 0)
                ->whereBetween('next_due_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
                ->count(),
            'overdue' => (clone $active)->where('status', PaymentPlanStatus::Overdue->value)->count(),
            'paid_this_month' => (clone $ownedPayments)
                ->where('status', PaymentTransactionStatus::Successful->value)
                ->whereBetween('payment_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
                ->distinct('student_id')
                ->count('student_id'),
            'collected_this_month' => (float) (clone $ownedPayments)
                ->where('status', PaymentTransactionStatus::Successful->value)
                ->whereBetween('payment_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
                ->sum('amount'),
            // Expected / pending only for live plans.
            'total_expected' => (float) (clone $active)->sum('total_amount'),
            // Collected forever — includes payments from deleted/withdrawn students.
            'total_collected' => (float) (clone $ownedPayments)
                ->where('status', PaymentTransactionStatus::Successful->value)
                ->sum('amount'),
            'total_pending' => (float) (clone $active)->sum('pending_amount'),
            'total_overdue' => (float) (clone $active)
                ->where('status', PaymentPlanStatus::Overdue->value)
                ->sum('overdue_amount'),
            // Written-off pending when students were deleted.
            'total_dead' => (float) StudentPaymentPlan::query()
                ->when(
                    $createdByUserId !== null,
                    fn (Builder $q) => $q->whereHas(
                        'student',
                        fn (Builder $s) => $s->where('created_by_user_id', $createdByUserId),
                    ),
                )
                ->sum('dead_amount'),
        ];
    }

    /**
     * @param  array<string, mixed>  $filters
     */
    public function listPlans(array $filters = [], int $perPage = 20): LengthAwarePaginator
    {
        $query = StudentPaymentPlan::query()
            ->where('is_active', true)
            ->where('status', '!=', PaymentPlanStatus::Withdrawn->value)
            ->with([
                'student.user',
                'student.academicLevel',
                'student.activeEnrollment.batch',
            ]);

        $status = $filters['status'] ?? null;
        if (is_string($status) && $status !== '' && $status !== 'all') {
            if ($status === 'pending_balance') {
                $query->where('pending_amount', '>', 0);
            } else {
                $query->where('status', $status);
            }
        }

        if (($filters['period'] ?? null) === 'this_month') {
            $start = AppClock::now()->copy()->startOfMonth()->toDateString();
            $end = AppClock::now()->copy()->endOfMonth()->toDateString();
            $query->whereBetween('next_due_date', [$start, $end]);
        } elseif (($filters['period'] ?? null) === 'last_month') {
            $start = AppClock::now()->copy()->subMonthNoOverflow()->startOfMonth()->toDateString();
            $end = AppClock::now()->copy()->subMonthNoOverflow()->endOfMonth()->toDateString();
            $query->whereBetween('next_due_date', [$start, $end]);
        }

        if (! empty($filters['from']) && ! empty($filters['to'])) {
            $query->whereBetween('next_due_date', [$filters['from'], $filters['to']]);
        }

        if (! empty($filters['payment_type'])) {
            $query->where('payment_type', $filters['payment_type']);
        }

        if (! empty($filters['preferred_mode'])) {
            $query->where('preferred_mode', $filters['preferred_mode']);
        }

        if (! empty($filters['level_id'])) {
            $query->whereHas('student', fn (Builder $q) => $q->where('level_id', $filters['level_id']));
        }

        if (! empty($filters['batch_id'])) {
            $query->whereHas('student.activeEnrollment', fn (Builder $q) => $q->where('batch_id', $filters['batch_id']));
        }

        if (! empty($filters['search'])) {
            $search = trim((string) $filters['search']);
            $query->whereHas('student', function (Builder $q) use ($search): void {
                $q->where('full_name', 'like', "%{$search}%")
                    ->orWhere('student_code', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        if (! empty($filters['created_by_user_id'])) {
            $query->whereHas(
                'student',
                fn (Builder $q) => $q->where('created_by_user_id', $filters['created_by_user_id']),
            );
        }

        return $query
            ->orderByRaw("case status when 'overdue' then 0 when 'pending' then 1 when 'partial' then 2 else 3 end")
            ->orderBy('next_due_date')
            ->paginate($perPage);
    }
}
