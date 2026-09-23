<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class TeacherPhotoController extends Controller
{
    public function show(string $file): BinaryFileResponse
    {
        if (! preg_match('/^[A-Za-z0-9._-]+$/', $file)) {
            abort(404);
        }

        $path = storage_path('app/teacher-photos/'.$file);
        if (! is_file($path)) {
            abort(404);
        }

        return response()->file($path, [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    public function options(Request $request, string $file)
    {
        return response('', 204, [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => $request->header('Access-Control-Request-Headers', '*'),
        ]);
    }
}
