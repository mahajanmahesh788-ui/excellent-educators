<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Meetings\GoogleMeetService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class GoogleMeetController extends Controller
{
    public function __construct(private readonly GoogleMeetService $googleMeet) {}

    public function show(): JsonResponse
    {
        return ApiResponse::success('Google Meet connection fetched.', $this->googleMeet->connectionStatus());
    }

    public function start(): JsonResponse
    {
        return ApiResponse::success(
            'Open this URL while signed into the Google account that should own Meet rooms.',
            $this->googleMeet->startAuthorization(),
        );
    }

    public function store(): JsonResponse
    {
        $created = $this->googleMeet->createSpace();

        return ApiResponse::success('Google Meet space created.', [
            'meeting_uri' => $created->meetUrl,
            'google_meeting_space_id' => $created->googleMeetingSpaceId,
        ], status: 201);
    }
}
