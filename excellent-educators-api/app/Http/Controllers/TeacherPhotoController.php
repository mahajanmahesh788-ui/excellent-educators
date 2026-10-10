<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class TeacherPhotoController extends Controller
{
    public function show(Request $request, string $file): BinaryFileResponse
    {
        if (! preg_match('/^[A-Za-z0-9._-]+$/', $file)) {
            abort(404);
        }

        $path = storage_path('app/teacher-photos/'.$file);
        if (! is_file($path)) {
            abort(404);
        }

        return response()->file($path, [
            'Access-Control-Allow-Origin' => $this->corsOrigin($request),
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Cache-Control' => 'private, max-age=3600',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function options(Request $request, string $file)
    {
        return response('', 204, [
            'Access-Control-Allow-Origin' => $this->corsOrigin($request),
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => $request->header('Access-Control-Request-Headers', '*'),
        ]);
    }

    private function corsOrigin(Request $request): string
    {
        $origin = trim((string) $request->headers->get('Origin', ''));
        $allowed = config('cors.allowed_origins', ['*']);
        if (! is_array($allowed) || $allowed === []) {
            $allowed = ['*'];
        }

        if ($origin !== '' && (in_array('*', $allowed, true) || in_array($origin, $allowed, true))) {
            return in_array('*', $allowed, true) ? '*' : $origin;
        }

        $frontend = trim((string) config('app.frontend_url', ''));
        if ($frontend !== '') {
            return rtrim($frontend, '/');
        }

        return in_array('*', $allowed, true) ? '*' : (string) ($allowed[0] ?? 'null');
    }
}
