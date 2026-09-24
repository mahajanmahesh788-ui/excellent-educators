<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Admin\UpdateSitePageRequest;
use App\Http\Resources\Api\V1\SitePageResource;
use App\Models\SitePage;
use App\Support\ApiResponse;
use App\Support\ErrorCode;
use Illuminate\Http\JsonResponse;

class SitePageController extends Controller
{
    public function index(): JsonResponse
    {
        return ApiResponse::success(
            'Site pages retrieved successfully.',
            SitePageResource::collection(SitePage::allOrdered())->resolve(),
        );
    }

    public function show(string $slug): JsonResponse
    {
        if (! in_array($slug, SitePage::slugs(), true)) {
            return ApiResponse::error('Page not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $page = SitePage::findBySlug($slug);
        if ($page === null) {
            return ApiResponse::error('Page not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        return ApiResponse::success(
            'Site page retrieved successfully.',
            SitePageResource::make($page)->resolve(),
        );
    }

    public function update(string $slug, UpdateSitePageRequest $request): JsonResponse
    {
        if (! in_array($slug, SitePage::slugs(), true)) {
            return ApiResponse::error('Page not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $page = SitePage::findBySlug($slug);
        if ($page === null) {
            return ApiResponse::error('Page not found.', ErrorCode::NOT_FOUND, null, 404);
        }

        $page->update($request->validated());

        return ApiResponse::success(
            'Site page updated successfully.',
            SitePageResource::make($page->fresh())->resolve(),
        );
    }
}
