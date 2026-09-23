<?php

namespace Database\Seeders;

use App\Actions\Teachers\CreateTeacher;
use App\Models\AcademicLevel;
use App\Models\TeacherProfile;
use App\Models\User;
use Database\Seeders\Support\DemoSeedData;
use Illuminate\Database\Seeder;

class DemoTeacherSeeder extends Seeder
{
    public function run(): void
    {
        $level = AcademicLevel::query()->where('name', 'Level 1')->first();
        if ($level === null) {
            $this->command?->warn('Level 1 missing — run LevelSeeder first. Skipping demo teachers.');

            return;
        }

        $createTeacher = app(CreateTeacher::class);
        $teacherIds = [];

        foreach (DemoSeedData::teachers() as $payload) {
            $existingUser = User::query()->where('email', $payload['email'])->first();
            if ($existingUser !== null) {
                $profile = $existingUser->teacherProfile;
                if ($profile instanceof TeacherProfile) {
                    $teacherIds[] = $profile->id;
                }

                continue;
            }

            $profile = $createTeacher->execute($payload);
            $teacherIds[] = $profile->id;
        }

        if ($teacherIds !== []) {
            $level->masterTeachers()->syncWithoutDetaching($teacherIds);
        }
    }
}
