<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Models\AcademicLevel;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherAvailabilityRule;
use App\Models\TeacherProfile;
use App\Models\User;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\LevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class TeacherAvailabilityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class, LevelSeeder::class]);
        Carbon::setTestNow(Carbon::parse('2026-09-15 08:00:00', 'Asia/Kolkata'));
    }

    public function test_new_teacher_defaults_to_full_time_six_to_eight(): void
    {
        $admin = $this->makeAdmin();
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/teachers', [
            'name' => 'Avail Teacher',
            'email' => 'avail-'.uniqid().'@excellenteducators.test',
            'password' => 'TeacherPass1!',
            'roles' => ['master_teacher'],
        ])->assertCreated()->json('data.id');

        $this->assertSame('full_time', TeacherProfile::query()->findOrFail($id)->work_type?->value);
        $this->assertSame(7, TeacherAvailabilityRule::query()->where('teacher_id', $id)->count());
        $this->assertSame(0, TeacherAvailabilityRule::query()->where('teacher_id', $id)->whereTime('start_time', '!=', '06:00:00')->count());

        $day = $this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/schedule/day?teacher_id='.$id.'&date=2026-09-16')
            ->assertOk()
            ->json('data');
        $available = collect($day['slots'])->where('status', 'available');
        $this->assertCount(28, $available);
        $this->assertSame('06:00', $available->first()['start']);
        $this->assertSame('19:30', $available->last()['start']);
    }

    public function test_admin_can_set_part_time_multiple_ranges_and_off_days(): void
    {
        $admin = $this->makeAdmin();
        $teacher = $this->createTeacherViaAdmin($admin);
        $weekly = $this->fullWeek();
        $weekly[1] = ['day_of_week' => 1, 'off' => false, 'ranges' => [
            ['start' => '06:00', 'end' => '10:00'],
            ['start' => '17:00', 'end' => '20:00'],
        ]];
        $weekly[3] = ['day_of_week' => 3, 'off' => true, 'ranges' => []];

        $this->withToken($this->tokenFor($admin))->putJson(
            '/api/v1/admin/schedule/teachers/'.$teacher->id.'/availability',
            ['work_type' => 'part_time', 'weekly' => $weekly],
        )->assertOk()->assertJsonPath('data.work_type', 'part_time');

        $this->assertSame(7, TeacherAvailabilityRule::query()->where('teacher_id', $teacher->id)->count());

        $monday = $this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/schedule/day?teacher_id='.$teacher->id.'&date=2026-09-21')
            ->json('data.slots');
        $byStart = collect($monday)->keyBy('start');
        $this->assertSame('available', $byStart['06:00']['status']);
        $this->assertSame('available', $byStart['09:30']['status']);
        $this->assertSame('unavailable', $byStart['10:00']['status']);
        $this->assertSame('unavailable', $byStart['12:00']['status']);
        $this->assertSame('available', $byStart['17:00']['status']);
        $this->assertSame('available', $byStart['19:30']['status']);

        $wednesday = collect($this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/schedule/day?teacher_id='.$teacher->id.'&date=2026-09-16')
            ->json('data.slots'));
        $this->assertTrue($wednesday->every(fn ($slot) => $slot['status'] === 'weekly_off'));
        $this->assertSame(0, $wednesday->where('status', 'available')->count());
    }

    public function test_special_date_override_and_unavailable_beat_weekly(): void
    {
        $admin = $this->makeAdmin();
        $teacher = $this->createTeacherViaAdmin($admin);

        $this->withToken($this->tokenFor($admin))->postJson(
            '/api/v1/admin/schedule/teachers/'.$teacher->id.'/availability/overrides',
            ['date' => '2026-09-20', 'type' => 'available', 'start' => '10:00', 'end' => '14:00'],
        )->assertCreated();

        $sunday = collect($this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/schedule/day?teacher_id='.$teacher->id.'&date=2026-09-20')
            ->json('data.slots'))->keyBy('start');
        $this->assertSame('unavailable', $sunday['06:00']['status']);
        $this->assertSame('available', $sunday['10:00']['status']);
        $this->assertSame('available', $sunday['13:30']['status']);
        $this->assertSame('unavailable', $sunday['14:00']['status']);

        $this->withToken($this->tokenFor($admin))->postJson(
            '/api/v1/admin/schedule/teachers/'.$teacher->id.'/availability/overrides',
            ['date' => '2026-09-20', 'type' => 'unavailable'],
        )->assertCreated();

        $blocked = collect($this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/schedule/day?teacher_id='.$teacher->id.'&date=2026-09-20')
            ->json('data.slots'));
        $this->assertSame(0, $blocked->where('status', 'available')->count());
        $this->assertTrue($blocked->every(fn ($slot) => $slot['status'] === 'unavailable'));
    }

    public function test_breaks_leave_and_bookings_block_and_leave_cannot_overlap_booking(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $admin = $this->makeAdmin();
        $adminToken = $this->tokenFor($admin);
        $teacherToken = $this->tokenFor($teacher->user);
        $this->withToken($teacherToken)->putJson('/api/v1/teacher/schedule/breaks', [
            'breakfast_start' => '09:00',
            'lunch_start' => '13:00',
        ])->assertOk();
        $booking = $this->book($student, $teacher, '2026-09-16', '11:00');
        $teacherToken = $this->tokenFor($teacher->user);
        $adminToken = $this->tokenFor($admin);

        $day = collect($this->withToken($adminToken)
            ->getJson('/api/v1/admin/schedule/day?teacher_id='.$teacher->id.'&date=2026-09-16')
            ->json('data.slots'))->keyBy('start');
        $this->assertSame('breakfast', $day['09:00']['status']);
        $this->assertSame('lunch', $day['13:00']['status']);
        $this->assertSame('booked', $day['11:00']['status']);

        $this->withToken($adminToken)->postJson('/api/v1/admin/schedule/teachers/'.$teacher->id.'/leaves', [
            'date' => '2026-09-16',
            'reason' => 'Clash',
            'start_time' => '11:00',
            'end_time' => '12:00',
        ])->assertUnprocessable()->assertJsonPath('error.code', 'LEAVE_OVERLAPS_BOOKING');

        $this->withToken($adminToken)->postJson('/api/v1/admin/schedule/teachers/'.$teacher->id.'/leaves', [
            'date' => '2026-09-16',
            'reason' => 'Later',
            'start_time' => '16:00',
            'end_time' => '17:00',
        ])->assertCreated();
        $this->assertSame('leave', collect($this->withToken($adminToken)
            ->getJson('/api/v1/admin/schedule/day?teacher_id='.$teacher->id.'&date=2026-09-16')
            ->json('data.slots'))->firstWhere('start', '16:00')['status']);

        $slots = $this->withToken($this->tokenFor($student->user))->getJson(
            '/api/v1/student/bookings/availability?teacher_id='.$teacher->id.'&date=2026-09-16',
        )->json('data.slots');
        $starts = collect($slots)->pluck('start');
        $this->assertFalse($starts->contains('09:00'));
        $this->assertFalse($starts->contains('11:00'));
        $this->assertFalse($starts->contains('13:00'));
        $this->assertFalse($starts->contains('16:00'));
        $this->assertTrue($starts->contains('10:00'));
        $this->assertTrue(collect($slots)->every(fn ($slot) => $slot['status'] === 'available'));

        $this->assertDatabaseHas('session_bookings', ['id' => $booking->id, 'status' => 'scheduled']);
        $weekly = $this->fullWeek();
        foreach ($weekly as $i => $dayRow) {
            $weekly[$i]['ranges'] = [['start' => '12:00', 'end' => '20:00']];
        }
        $saved = $this->withToken($this->tokenFor($admin))->putJson(
            '/api/v1/admin/schedule/teachers/'.$teacher->id.'/availability',
            ['work_type' => 'part_time', 'weekly' => $weekly],
        )->assertOk()->json('data.booking_warnings');
        $this->assertNotEmpty($saved);
        $this->assertDatabaseHas('session_bookings', ['id' => $booking->id, 'status' => 'scheduled']);
        $this->assertSame('11:00', $booking->fresh()->starts_at->timezone('Asia/Kolkata')->format('H:i'));
    }

    public function test_teacher_cannot_modify_availability_and_double_book_is_rejected(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $this->withToken($this->tokenFor($teacher->user))
            ->putJson('/api/v1/admin/schedule/teachers/'.$teacher->id.'/availability', [
                'weekly' => $this->fullWeek(),
            ])
            ->assertForbidden();

        $this->book($student, $teacher, '2026-09-16', '10:00');
        $other = $this->makeSecondStudent();
        $this->withToken($this->tokenFor($other->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertStatus(409)->assertJsonPath('error.code', 'SLOT_UNAVAILABLE');
    }

    /**
     * @return list<array{day_of_week: int, off: bool, ranges: list<array{start: string, end: string}>}>
     */
    private function fullWeek(): array
    {
        $days = [];
        foreach (range(0, 6) as $weekday) {
            $days[] = [
                'day_of_week' => $weekday,
                'off' => false,
                'ranges' => [['start' => '06:00', 'end' => '20:00']],
            ];
        }

        return $days;
    }

    private function createTeacherViaAdmin(User $admin): TeacherProfile
    {
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/teachers', [
            'name' => 'Avail Teacher Two',
            'email' => 'avail-2-'.uniqid().'@excellenteducators.test',
            'password' => 'TeacherPass1!',
            'roles' => ['master_teacher'],
        ])->assertCreated()->json('data.id');

        return TeacherProfile::query()->with('user')->findOrFail($id);
    }

    /**
     * @return array{0: StudentProfile, 1: TeacherProfile}
     */
    private function makeStudentWithTeacher(): array
    {
        $admin = $this->makeAdmin();
        $teacher = $this->createTeacherViaAdmin($admin);
        AcademicLevel::query()->where('name', 'Level 1')->firstOrFail()
            ->masterTeachers()->syncWithoutDetaching([$teacher->id]);
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Avail Student',
            'email' => 'avail-stu-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'class_grade' => 6,
        ])->assertCreated()->json('data.id');

        return [StudentProfile::query()->with('user')->findOrFail($id), $teacher];
    }

    private function makeSecondStudent(): StudentProfile
    {
        $admin = $this->makeAdmin();
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Avail Student Two',
            'email' => 'avail-stu-2-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '97'.random_int(10000000, 99999999),
            'class_grade' => 6,
        ])->assertCreated()->json('data.id');

        return StudentProfile::query()->with('user')->findOrFail($id);
    }

    private function book(StudentProfile $student, TeacherProfile $teacher, string $date, string $start): SessionBooking
    {
        $id = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => $date,
            'start' => $start,
        ])->assertCreated()->json('data.id');

        return SessionBooking::query()->findOrFail($id);
    }

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'ops-avail-'.uniqid().'@excellenteducators.test']);
        $user->assignRole(RoleName::OperationalAdmin->value);

        return $user;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('test')->plainTextToken;
    }
}
