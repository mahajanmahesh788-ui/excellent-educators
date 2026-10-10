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
        $levels = AcademicLevel::query()
            ->whereIn('name', ['Level 1', 'Level 2'])
            ->get();

        if ($levels->isEmpty()) {
            $this->command?->warn('Levels missing — run LevelSeeder first. Skipping demo teachers.');

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
            foreach ($levels as $level) {
                $level->masterTeachers()->syncWithoutDetaching($teacherIds);
            }
        }

        $this->command?->info('Seeded '.count($teacherIds).' demo teacher(s). Password: '.DemoSeedData::TEACHER_PASSWORD);
        $this->command?->info('Logins: teacher1@yopmail.com … teacher3@yopmail.com');
    }
}
