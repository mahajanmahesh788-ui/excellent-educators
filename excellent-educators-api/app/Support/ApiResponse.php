<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

final class ApiResponse
{
    public static function success(
        string $message,
        mixed $data = null,
        array $meta = [],
        int $status = 200,
    ): JsonResponse {
        $payload = [
            'success' => true,
            'message' => $message,
            'data' => $data,
        ];

        $meta = self::withRequestId($meta);

        if ($meta !== []) {
            $payload['meta'] = $meta;
        }

        return response()->json($payload, $status);
    }

    public static function error(
        string $message,
        string $code,
        mixed $details = null,
        int $status = 400,
        array $meta = [],
    ): JsonResponse {
        $payload = [
            'success' => false,
            'message' => $message,
            'error' => [
                'code' => $code,
                'details' => $details,
            ],
            'meta' => self::withRequestId($meta),
        ];

        return response()->json($payload, $status);
    }

    /**
     * @param  array<string, mixed>  $meta
     * @return array<string, mixed>
     */
    private static function withRequestId(array $meta): array
    {
        $requestId = request()->headers->get('X-Request-Id')
            ?? request()->attributes->get('request_id');

        if (is_string($requestId) && $requestId !== '') {
            $meta['request_id'] = $requestId;
        }

        return $meta;
    }
}
