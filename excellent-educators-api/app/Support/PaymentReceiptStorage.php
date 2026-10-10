<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

final class PaymentReceiptStorage
{
    public const DISK = 'local';

    public const LEGACY_DISK = 'public';

    public static function store(UploadedFile $file, string $studentId): string
    {
        return $file->store('payment-receipts/'.$studentId, self::DISK);
    }

    public static function delete(?string $path): void
    {
        if (! filled($path)) {
            return;
        }

        Storage::disk(self::DISK)->delete($path);
        Storage::disk(self::LEGACY_DISK)->delete($path);
    }

    public static function exists(?string $path): bool
    {
        if (! filled($path)) {
            return false;
        }

        return Storage::disk(self::DISK)->exists($path)
            || Storage::disk(self::LEGACY_DISK)->exists($path);
    }

    public static function response(?string $path, string $downloadName = 'receipt.pdf'): StreamedResponse
    {
        if (! filled($path)) {
            abort(404);
        }

        if (! Storage::disk(self::DISK)->exists($path)
            && Storage::disk(self::LEGACY_DISK)->exists($path)) {
            $contents = Storage::disk(self::LEGACY_DISK)->get($path);
            if (is_string($contents)) {
                Storage::disk(self::DISK)->put($path, $contents);
                Storage::disk(self::LEGACY_DISK)->delete($path);
            }
        }

        if (! Storage::disk(self::DISK)->exists($path)) {
            abort(404);
        }

        return Storage::disk(self::DISK)->response(
            $path,
            $downloadName,
            [
                'Content-Type' => 'application/pdf',
                'Cache-Control' => 'private, no-store',
                'X-Content-Type-Options' => 'nosniff',
            ],
        );
    }
}
