<?php

namespace Database\Seeders;

use App\Actions\Assessments\ActivateAptitudeAssessment;
use App\Actions\Assessments\CreateAptitudeAssessment;
use App\Enums\RoleName;
use App\Models\AcademicLevel;
use App\Models\AptitudeAssessment;
use App\Models\User;
use Database\Seeders\Support\DemoSeedData;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Auth;

class DemoAptitudeAssessmentSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::query()->where('email', 'admin1@excellenteducators.test')->first()
            ?? User::query()->role(RoleName::SuperAdmin->value)->first();

        if ($admin === null) {
            $this->command?->warn('No admin user — skipping aptitude assessments.');

            return;
        }

        Auth::login($admin);

        $create = app(CreateAptitudeAssessment::class);
        $activate = app(ActivateAptitudeAssessment::class);
        $seeded = 0;

        foreach (DemoSeedData::aptitudeAssessments() as $payload) {
            $existing = AptitudeAssessment::query()->where('title', $payload['title'])->first();
            if ($existing !== null) {
                $this->attachToLevel($existing, (int) $payload['level_number']);
                $this->command?->info("Assessment \"{$payload['title']}\" already exists — linked to Level {$payload['level_number']}.");

                continue;
            }

            $assessment = $create->execute($admin, [
                'title' => $payload['title'],
                'description' => $payload['description'] ?? null,
                'questions' => $payload['questions'],
            ]);

            $activate->execute($assessment, $admin);
            $this->attachToLevel($assessment, (int) $payload['level_number']);
            $seeded++;
        }

        Auth::logout();

        $this->command?->info("Seeded {$seeded} aptitude assessment(s).");
    }

    private function attachToLevel(AptitudeAssessment $assessment, int $levelNumber): void
    {
        $level = AcademicLevel::query()->where('number', $levelNumber)->first()
            ?? AcademicLevel::query()->where('name', "Level {$levelNumber}")->first();

        if ($level === null) {
            $this->command?->warn("Level {$levelNumber} missing — assessment not linked.");

            return;
        }

        $level->aptitudeAssessments()->syncWithoutDetaching([$assessment->id]);
    }
}
