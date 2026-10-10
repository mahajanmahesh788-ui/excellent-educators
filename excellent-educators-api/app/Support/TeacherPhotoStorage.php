<?php

namespace App\Support;

use App\Models\TeacherProfile;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;

final class TeacherPhotoStorage
{
    public const ROUTE = 'teacher.photo';

    public const SIGNED_TTL_HOURS = 12;

    public static function store(UploadedFile $file, ?TeacherProfile $teacher = null): string
    {
        $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');
        if (! in_array($extension, ['jpg', 'jpeg', 'png', 'webp'], true)) {
            $extension = 'jpg';
        }

        $base = Str::slug($teacher?->full_name ?: 'teacher');
        if ($base === '') {
            $base = 'teacher';
        }

        $directory = storage_path('app/teacher-photos');
        if (! is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        do {
            $filename = $base.'-'.Str::lower(Str::random(8)).'.'.$extension;
            $path = $directory.DIRECTORY_SEPARATOR.$filename;
        } while (is_file($path));

        self::deleteLocalPhoto($teacher?->photo_url);

        $file->move($directory, $filename);

        return url('/media/teachers/'.$filename);
    }

    public static function accessibleUrl(?string $storedUrl): ?string
    {
        if (! filled($storedUrl)) {
            return null;
        }

        $filename = self::filenameFromUrl($storedUrl);
        if ($filename === null) {
            return $storedUrl;
        }

        return URL::temporarySignedRoute(
            self::ROUTE,
            now()->addHours(self::SIGNED_TTL_HOURS),
            ['file' => $filename],
        );
    }

    public static function filenameFromUrl(?string $photoUrl): ?string
    {
        if (! filled($photoUrl)) {
            return null;
        }

        $path = parse_url($photoUrl, PHP_URL_PATH);
        if (! is_string($path) || ! preg_match('#/media/teachers/([A-Za-z0-9._-]+)$#', $path, $matches)) {
            return null;
        }

        return $matches[1];
    }

    public static function deleteLocalPhoto(?string $photoUrl): void
    {
        $filename = self::filenameFromUrl($photoUrl);
        if ($filename === null) {
            return;
        }

        $file = storage_path('app/teacher-photos/'.$filename);
        if (is_file($file)) {
            @unlink($file);
        }
    }
}
