<?php

namespace Tests\Concerns;

use App\Enums\RoleName;
use App\Models\AcademicLevel;
use App\Models\Dimension;
use App\Models\StudentProfile;
use App\Models\TeacherProfile;
use App\Models\User;

trait CreatesActors
{
    protected function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('test')->plainTextToken;
    }

    protected function makeAdmin(): User
    {
        $user = User::factory()->create([
            'email' => 'ops-'.uniqid().'@excellenteducators.test',
        ]);
        $user->assignRole(RoleName::OperationalAdmin->value);

        return $user;
    }

    protected function makeMasterTeacher(?string $name = null, ?string $email = null): TeacherProfile
    {
        $user = User::factory()->create([
            'name' => $name ?? 'Master Teacher',
            'email' => $email ?? 'mt-'.uniqid().'@excellenteducators.test',
        ]);
        $user->assignRole(RoleName::MasterTeacher->value);

        $profile = TeacherProfile::query()->create([
            'user_id' => $user->id,
            'full_name' => $name ?? $user->name,
            'status' => 'active',
        ]);
        $profile->setRelation('user', $user);

        return $profile;
    }

    protected function makeStudentViaAdmin(
        User $admin,
        string $name = 'Test Student',
        ?string $emailPrefix = null,
    ): StudentProfile {
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => $name,
            'email' => ($emailPrefix ?? 'stu').'-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'class_grade' => 6,
            'gender' => 'female',
        ])->assertCreated()->json('data.id');

        return StudentProfile::query()->with('user')->findOrFail($id);
    }

    /**
     * @return array{0: StudentProfile, 1: TeacherProfile}
     */
    protected function makeStudentWithTeacher(): array
    {
        $admin = $this->makeAdmin();
        $teacher = $this->makeMasterTeacher();
        AcademicLevel::query()->where('name', 'Level 1')->firstOrFail()
            ->masterTeachers()->syncWithoutDetaching([$teacher->id]);

        return [$this->makeStudentViaAdmin($admin), $teacher];
    }

    /**
     * @param  array<string, mixed>  $extra
     * @return array<string, mixed>
     */
    protected function dimensionRatingPayload(int $rating = 6, array $extra = []): array
    {
        return array_merge([
            'positive_points' => 'Good work in class',
            'areas_for_improvement' => 'Keep practicing',
            'discussed_in_class' => 'Talked about next goals',
            'items' => Dimension::query()->orderBy('display_order')->get()->map(fn (Dimension $dimension) => [
                'target_type' => 'dimension',
                'target_id' => $dimension->id,
                'rating' => $rating,
            ])->all(),
        ], $extra);
    }
}
