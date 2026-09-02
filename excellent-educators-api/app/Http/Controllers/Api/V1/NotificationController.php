<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\V1\UserNotificationResource;
use App\Models\UserNotification;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = UserNotification::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->limit(100)
            ->get();

        return ApiResponse::success(
            'Notifications fetched successfully.',
            UserNotificationResource::collection($notifications)->resolve(),
        );
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $count = UserNotification::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->count();

        return ApiResponse::success(
            'Unread count fetched successfully.',
            ['unread_count' => $count],
        );
    }

    public function markRead(Request $request, UserNotification $notification): JsonResponse
    {
        if ($notification->user_id !== $request->user()->id) {
            abort(404);
        }

        if ($notification->read_at === null) {
            $notification->update(['read_at' => now()]);
        }

        return ApiResponse::success(
            'Notification marked as read.',
            UserNotificationResource::make($notification->refresh())->resolve(),
        );
    }

    public function markAllRead(Request $request): JsonResponse
    {
        UserNotification::query()
            ->where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return ApiResponse::success('All notifications marked as read.');
    }
}
