<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Actions\Notifications\BroadcastAdminAnnouncement;
use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificationBroadcastController extends Controller
{
    public function store(Request $request, BroadcastAdminAnnouncement $broadcast): JsonResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:120'],
            'body' => ['required', 'string', 'max:2000'],
            'audience' => ['required', Rule::in(['students', 'teachers', 'all_users'])],
        ]);

        $result = $broadcast->execute(
            $data['title'],
            $data['body'],
            $data['audience'],
            $request->user(),
        );

        return ApiResponse::success(
            "Announcement sent to {$result['sent']} recipient(s).",
            $result,
            status: 201,
        );
    }
}
