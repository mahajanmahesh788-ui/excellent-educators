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

        $monthStartDate = $monthStart->toDateString();
        $monthEndDate = $monthEnd->toDateString();

        $planStats = (clone $active)
            ->selectRaw('sum(case when pending_amount > 0 then 1 else 0 end) as all_pending')
            ->selectRaw('sum(case when pending_amount > 0 and next_due_date between ? and ? then 1 else 0 end) as due_this_month', [
                $monthStartDate,
                $monthEndDate,
            ])
            ->selectRaw('sum(case when status = ? then 1 else 0 end) as overdue', [
                PaymentPlanStatus::Overdue->value,
            ])
            ->selectRaw('coalesce(sum(total_amount), 0) as total_expected')
            ->selectRaw('coalesce(sum(pending_amount), 0) as total_pending')
            ->selectRaw('coalesce(sum(case when status = ? then overdue_amount else 0 end), 0) as total_overdue', [
                PaymentPlanStatus::Overdue->value,
            ])
            ->first();

        $paymentStats = (clone $ownedPayments)
            ->where('status', PaymentTransactionStatus::Successful->value)
            ->selectRaw('count(distinct case when payment_date between ? and ? then student_id end) as paid_this_month', [
                $monthStartDate,
                $monthEndDate,
            ])
            ->selectRaw('coalesce(sum(case when payment_date between ? and ? then amount else 0 end), 0) as collected_this_month', [
                $monthStartDate,
                $monthEndDate,
            ])
            ->selectRaw('coalesce(sum(amount), 0) as total_collected')
            ->first();

        return [
            'all_pending' => (int) ($planStats->all_pending ?? 0),
            'due_this_month' => (int) ($planStats->due_this_month ?? 0),
            'overdue' => (int) ($planStats->overdue ?? 0),
            'paid_this_month' => (int) ($paymentStats->paid_this_month ?? 0),
            'collected_this_month' => (float) ($paymentStats->collected_this_month ?? 0),
            'total_expected' => (float) ($planStats->total_expected ?? 0),
            'total_collected' => (float) ($paymentStats->total_collected ?? 0),
            'total_pending' => (float) ($planStats->total_pending ?? 0),
            'total_overdue' => (float) ($planStats->total_overdue ?? 0),
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
