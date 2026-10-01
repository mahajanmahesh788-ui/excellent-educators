<?php

namespace App\Http\Controllers\Api\V1\MasterTeacher;

use App\Http\Controllers\Controller;
use App\Models\AcademicLevel;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class AcademicLevelController extends Controller
{
    public function index(): JsonResponse
    {
        $levels = AcademicLevel::query()
            ->orderBy('created_at')
            ->get(['id', 'name', 'academic_year', 'status'])
            ->map(fn (AcademicLevel $level) => [
                'id' => $level->id,
                'name' => $level->name,
                'academic_year' => $level->academic_year,
                'status' => $level->status,
            ])
            ->values()
            ->all();

        return ApiResponse::success('Levels fetched successfully.', $levels);
    }
}
