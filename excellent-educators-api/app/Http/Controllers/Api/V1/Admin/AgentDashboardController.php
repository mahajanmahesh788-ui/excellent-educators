<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\ProfileStatus;
use App\Http\Controllers\Controller;
use App\Models\StudentProfile;
use App\Payments\PaymentOverviewService;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AgentDashboardController extends Controller
{
    public function __construct(
        private readonly PaymentOverviewService $overview,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user === null || ! $user->isAgent()) {
            return ApiResponse::error('This action is unauthorized.', ErrorCode::FORBIDDEN, null, 403);
        }

        $actorId = $user->id;

        $studentsRegistered = StudentProfile::query()
            ->where('created_by_user_id', $actorId)
            ->count();

        $studentsActive = StudentProfile::query()
            ->where('created_by_user_id', $actorId)
            ->where('status', ProfileStatus::Active->value)
            ->count();

        $payments = $this->overview->summaryCards($actorId);

        return ApiResponse::success('Agent dashboard fetched successfully.', array_merge(
            [
                'students_registered' => $studentsRegistered,
                'students_active' => $studentsActive,
            ],
            $payments,
        ));
    }
}
