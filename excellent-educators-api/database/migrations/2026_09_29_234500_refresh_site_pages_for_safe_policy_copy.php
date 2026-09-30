<?php

use App\Models\SitePage;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        foreach (SitePage::defaultPages() as $page) {
            SitePage::query()->updateOrCreate(
                ['slug' => $page['slug']],
                [
                    'title' => $page['title'],
                    'body' => $page['body'],
                ],
            );
        }
    }

    public function down(): void
    {
        // Content refresh only; previous wording is not reconstructed.
    }
};
