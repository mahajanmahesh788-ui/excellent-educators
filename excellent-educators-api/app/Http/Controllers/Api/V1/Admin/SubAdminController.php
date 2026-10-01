<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\SubAdmins\CreateSubAdmin;
use App\Actions\SubAdmins\UpdateSubAdmin;
use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\StoreSubAdminRequest;
use App\Http\Requests\Api\V1\Admin\UpdateSubAdminRequest;
use App\Http\Resources\Api\V1\SubAdminResource;
use App\Models\AdminActivityEvent;
use App\Models\StudentPaymentPlan;
use App\Models\StudentProfile;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\SearchRank;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SubAdminController extends Controller
{
    public function catalog(): JsonResponse
    {
        return ApiResponse::success('Permission catalog fetched successfully.', PermissionName::catalog());
    }

    public function index(Request $request): JsonResponse
    {
        $admins = User::query()
            ->role(RoleName::SubAdmin->value)
            ->with(['adminProfile', 'permissions', 'roles'])
            ->when($request->string('search')->toString(), function ($query, string $search): void {
                $query->where(function ($inner) use ($search): void {
                    $inner->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhereHas('adminProfile', fn ($profile) => $profile->where('phone', 'like', "%{$search}%"));
                });
            })
            ->when($request->filled('status'), fn ($query) => $query->where('status', $request->string('status')));

        $search = trim($request->string('search')->toString());
        if ($search !== '') {
            SearchRank::orderBy($admins, $search, ['users.name', 'users.email']);
        }

        $admins = $admins
            ->orderBy('name')
            ->paginate((int) $request->integer('per_page', 15));

        return ApiResponse::success(
            'Sub admins fetched successfully.',
            SubAdminResource::collection($admins)->resolve(),
            [
                'page' => $admins->currentPage(),
                'per_page' => $admins->perPage(),
                'total' => $admins->total(),
            ],
        );
    }

    public function store(StoreSubAdminRequest $request, CreateSubAdmin $create): JsonResponse
    {
        $user = $create->execute($request->validated());

        return ApiResponse::success('Sub admin created successfully.', SubAdminResource::make($user)->resolve(), status: 201);
    }

    public function show(User $subAdmin): JsonResponse
    {
        $this->ensureSubAdmin($subAdmin);
        $subAdmin->load(['adminProfile', 'permissions', 'roles']);

        return ApiResponse::success('Sub admin fetched successfully.', SubAdminResource::make($subAdmin)->resolve());
    }

    public function history(User $subAdmin): JsonResponse
    {
        $this->ensureSubAdmin($subAdmin);
        $isAgent = $subAdmin->adminProfile?->isAgent() ?? false;

        $students = StudentProfile::query()
            ->where('created_by_user_id', $subAdmin->id)
            ->with([
                'user:id,email',
                'paymentPlans' => fn ($query) => $query
                    ->where('is_active', true)
                    ->orderByDesc('updated_at'),
            ])
            ->get()
            ->keyBy('id');

        $studentIds = $students->keys()->all();
        $paymentTotals = $studentIds === []
            ? (object) ['total_collected' => 0, 'total_pending' => 0]
            : StudentPaymentPlan::query()
                ->whereIn('student_id', $studentIds)
                ->where('is_active', true)
                ->selectRaw(
                    'coalesce(sum(paid_amount), 0) as total_collected, coalesce(sum(pending_amount), 0) as total_pending'
                )
                ->first();

        $query = AdminActivityEvent::query()
            ->where('actor_id', $subAdmin->id)
            ->orderByDesc('occurred_at');

        if ($isAgent) {
            $query->where('type', 'student.create');
        }

        $events = $query
            ->limit(500)
            ->get()
            ->map(function (AdminActivityEvent $event) use ($students) {
                $studentId = $event->meta['student_id'] ?? null;
                if (! is_string($studentId) || $studentId === '') {
                    $studentId = is_string($event->related_id) ? $event->related_id : null;
                }

                $student = $studentId !== null ? $students->get($studentId) : null;

                $studentName = $event->meta['student_name'] ?? null;
                if (! is_string($studentName) || $studentName === '') {
                    $studentName = $student?->full_name;
                }
                if (! is_string($studentName) || $studentName === '') {
                    $studentName = self::studentNameFromMessage($event->message);
                }

                $plan = $student?->paymentPlans->first();
                $paymentStatus = self::paymentStatusForPlan($plan);

                return [
                    'occurred_at' => $event->occurred_at?->timezone(config('app.timezone'))->toIso8601String(),
                    'type' => $event->type,
                    'message' => $event->message,
                    'student_id' => $student?->id ?? $studentId,
                    'student_name' => $studentName,
                    'student_email' => $student?->user?->email,
                    'student_phone' => $student?->phone,
                    'payment_status' => $paymentStatus,
                ];
            })
            ->all();

        $createdCount = AdminActivityEvent::query()
            ->where('actor_id', $subAdmin->id)
            ->where('type', 'student.create')
            ->count();

        return ApiResponse::success('Sub admin history fetched successfully.', $events, [
            'students_created_count' => $createdCount,
            'is_agent' => $isAgent,
            'total_collected' => round((float) ($paymentTotals->total_collected ?? 0), 2),
            'total_pending' => round((float) ($paymentTotals->total_pending ?? 0), 2),
        ]);
    }

    private static function paymentStatusForPlan(?StudentPaymentPlan $plan): ?string
    {
        if ($plan === null) {
            return null;
        }

        $paid = round((float) $plan->paid_amount, 2);
        $pending = round((float) $plan->pending_amount, 2);

        if ($pending <= 0) {
            return 'full';
        }
        if ($paid > 0) {
            return 'partial';
        }

        return 'unpaid';
    }

    private static function studentNameFromMessage(?string $message): ?string
    {
        if ($message === null || $message === '') {
            return null;
        }
        if (preg_match('/Created student login for (.+)$/', $message, $matches) === 1) {
            return trim($matches[1]);
        }

        return null;
    }

    public function update(UpdateSubAdminRequest $request, User $subAdmin, UpdateSubAdmin $update): JsonResponse
    {
        $this->ensureSubAdmin($subAdmin);
        $user = $update->execute($subAdmin, $request->validated());

        return ApiResponse::success('Sub admin updated successfully.', SubAdminResource::make($user)->resolve());
    }

    public function destroy(User $subAdmin): JsonResponse
    {
        $this->ensureSubAdmin($subAdmin);
        $subAdmin->adminProfile?->delete();
        $subAdmin->syncPermissions([]);
        $subAdmin->delete();

        return ApiResponse::success('Sub admin deleted successfully.');
    }

    private function ensureSubAdmin(User $user): void
    {
        if (! $user->hasRole(RoleName::SubAdmin->value)) {
            abort(404);
        }
    }
}
