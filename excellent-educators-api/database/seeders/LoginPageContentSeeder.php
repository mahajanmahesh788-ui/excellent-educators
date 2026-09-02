<?php

namespace Database\Seeders;

use App\Models\LoginPageContent;
use Illuminate\Database\Seeder;

class LoginPageContentSeeder extends Seeder
{
    public function run(): void
    {
        if (LoginPageContent::query()->exists()) {
            return;
        }

        LoginPageContent::query()->create(LoginPageContent::defaultAttributes());
    }
}
