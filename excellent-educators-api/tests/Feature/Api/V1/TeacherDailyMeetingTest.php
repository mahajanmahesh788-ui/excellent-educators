<?php

namespace Tests\Feature\Api\V1;

use App\Enums\RoleName;
use App\Enums\SessionBookingStatus;
use App\Exceptions\ApiException;
use App\Meetings\CreatedGoogleMeet;
use App\Meetings\FakeGoogleMeetGateway;
use App\Meetings\GoogleMeetGateway;
use App\Meetings\TeacherDailyMeetingService;
use App\Models\AcademicLevel;
use App\Models\SessionBooking;
use App\Models\StudentProfile;
use App\Models\TeacherDailyMeeting;
use App\Models\TeacherProfile;
use App\Models\User;
use App\Support\ErrorCode;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\LevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class TeacherDailyMeetingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class, LevelSeeder::class]);
        Carbon::setTestNow(Carbon::parse('2026-09-15 08:00:00', 'Asia/Kolkata'));
        $this->app->instance(GoogleMeetGateway::class, new FakeGoogleMeetGateway);
    }

    public function test_first_booking_creates_daily_meet_and_student_receives_url(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $payload = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data');

        $this->assertNotEmpty($payload['meeting_url']);
        $this->assertStringStartsWith('https://meet.google.com/', $payload['meeting_url']);
        $this->assertSame(1, TeacherDailyMeeting::query()->count());
        $this->assertSame($payload['meeting_url'], TeacherDailyMeeting::query()->first()->meet_url);
    }

    public function test_second_booking_same_teacher_date_reuses_meet(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $first = $this->book($student, $teacher, 'introduction_call', '2026-09-16', '10:00');
        $other = $this->makeSecondStudent();
        $this->completeIntroduction($other, $teacher);
        $second = $this->withToken($this->tokenFor($other->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'master_class',
            'date' => '2026-09-16',
            'start' => '11:00',
        ])->assertCreated()->json('data');

        $this->assertSame(1, TeacherDailyMeeting::query()->count());
        $firstUrl = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/bookings')->json('data.0.meeting_url');
        $this->assertSame($firstUrl, $second['meeting_url']);
        $this->assertNotNull(SessionBooking::query()->find($first->id));
    }

    public function test_different_teacher_same_date_creates_different_meet(): void
    {
        [$studentA, $teacherA] = $this->makeStudentWithTeacher();
        [$studentB, $teacherB] = $this->makeStudentWithTeacher();
        $urlA = $this->withToken($this->tokenFor($studentA->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacherA->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data.meeting_url');
        $urlB = $this->withToken($this->tokenFor($studentB->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacherB->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data.meeting_url');

        $this->assertNotSame($urlA, $urlB);
        $this->assertSame(2, TeacherDailyMeeting::query()->count());
    }

    public function test_same_teacher_different_date_creates_different_meet(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $first = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data.meeting_url');

        $this->withToken($this->tokenFor($student->user))->putJson(
            '/api/v1/student/bookings/'.$this->latestBookingId($student),
            ['teacher_id' => $teacher->id, 'date' => '2026-09-17', 'start' => '10:00'],
        )->assertOk();

        $second = $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/bookings')->assertOk()->json('data.0.meeting_url');

        $this->assertNotSame($first, $second);
        $this->assertSame(2, TeacherDailyMeeting::query()->count());
    }

    public function test_get_or_create_does_not_create_two_records_for_same_teacher_date(): void
    {
        $gateway = new FakeGoogleMeetGateway;
        $this->app->instance(GoogleMeetGateway::class, $gateway);
        $teacher = $this->makeMasterTeacher();
        $service = $this->app->make(TeacherDailyMeetingService::class);

        $first = $service->getOrCreate($teacher, '2026-09-18');
        $second = $service->getOrCreate($teacher, '2026-09-18');

        $this->assertSame($first->id, $second->id);
        $this->assertSame($first->meet_url, $second->meet_url);
        $this->assertSame(1, $gateway->createCount);
        $this->assertSame(1, TeacherDailyMeeting::query()->count());
    }

    public function test_failed_booking_validation_does_not_create_meet(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '03:00',
        ])->assertUnprocessable();

        $this->assertSame(0, TeacherDailyMeeting::query()->count());
        $this->assertSame(0, SessionBooking::query()->count());
    }

    public function test_google_failure_does_not_create_booking(): void
    {
        $this->app->instance(GoogleMeetGateway::class, new class implements GoogleMeetGateway
        {
            public function createDailyMeet(TeacherProfile $teacher, string $date): CreatedGoogleMeet
            {
                throw new ApiException(ErrorCode::MEETING_CREATE_FAILED, 'Unable to create the meeting right now. Please try again.', 503);
            }
        });
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])
            ->assertStatus(503)
            ->assertJsonPath('error.code', 'MEETING_CREATE_FAILED')
            ->assertJsonPath('message', 'Unable to create the meeting right now. Please try again.');

        $this->assertSame(0, SessionBooking::query()->count());
    }

    public function test_reschedule_same_date_keeps_same_meet(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $created = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data');

        $moved = $this->withToken($this->tokenFor($student->user))->putJson('/api/v1/student/bookings/'.$created['id'], [
            'teacher_id' => $teacher->id,
            'date' => '2026-09-16',
            'start' => '12:00',
        ])->assertOk()->json('data');

        $this->assertSame($created['meeting_url'], $moved['meeting_url']);
        $this->assertSame(1, TeacherDailyMeeting::query()->count());
    }

    public function test_reschedule_to_another_date_gets_or_creates_daily_meet(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $created = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data');

        $moved = $this->withToken($this->tokenFor($student->user))->putJson('/api/v1/student/bookings/'.$created['id'], [
            'teacher_id' => $teacher->id,
            'date' => '2026-09-20',
            'start' => '10:00',
        ])->assertOk()->json('data');

        $this->assertNotSame($created['meeting_url'], $moved['meeting_url']);
        $this->assertSame(2, TeacherDailyMeeting::query()->count());
    }

    public function test_reschedule_to_another_teacher_uses_that_teacher_daily_meet(): void
    {
        [$student, $teacherA] = $this->makeStudentWithTeacher();
        $teacherB = $this->makeMasterTeacher();
        AcademicLevel::query()->where('name', 'Level 1')->firstOrFail()
            ->masterTeachers()->syncWithoutDetaching([$teacherB->id]);

        $created = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacherA->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data');

        $moved = $this->withToken($this->tokenFor($student->user))->putJson('/api/v1/student/bookings/'.$created['id'], [
            'teacher_id' => $teacherB->id,
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertOk()->json('data');

        $this->assertNotSame($created['meeting_url'], $moved['meeting_url']);
        $this->assertTrue(
            TeacherDailyMeeting::query()->where('teacher_id', $teacherB->id)->whereDate('date', '2026-09-16')->exists(),
        );
    }

    public function test_cancelled_booking_does_not_delete_daily_meeting(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $created = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data');

        $admin = $this->makeAdmin();
        $this->withToken($this->tokenFor($admin))->deleteJson('/api/v1/admin/schedule/bookings/'.$created['id'])
            ->assertOk();

        $this->assertSame(SessionBookingStatus::Cancelled, SessionBooking::query()->find($created['id'])->status);
        $this->assertSame(1, TeacherDailyMeeting::query()->count());
        $this->assertSame($created['meeting_url'], TeacherDailyMeeting::query()->first()->meet_url);
    }

    public function test_teacher_and_admin_receive_the_same_meet_url(): void
    {
        [$student, $teacher] = $this->makeStudentWithTeacher();
        $created = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => 'introduction_call',
            'date' => '2026-09-16',
            'start' => '10:00',
        ])->assertCreated()->json('data');

        $teacherDay = $this->withToken($this->tokenFor($teacher->user))
            ->getJson('/api/v1/teacher/schedule/day?date=2026-09-16')
            ->assertOk()
            ->json('data.bookings.0.meeting_url');

        $admin = $this->makeAdmin();
        $adminUrl = $this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/schedule/bookings?teacher_id='.$teacher->id)
            ->assertOk()
            ->json('data.0.meeting_url');

        $this->assertSame($created['meeting_url'], $teacherDay);
        $this->assertSame($created['meeting_url'], $adminUrl);
    }

    /**
     * @return array{0: StudentProfile, 1: TeacherProfile}
     */
    private function makeStudentWithTeacher(): array
    {
        $admin = $this->makeAdmin();
        $teacher = $this->makeMasterTeacher();
        AcademicLevel::query()->where('name', 'Level 1')->firstOrFail()
            ->masterTeachers()->syncWithoutDetaching([$teacher->id]);

        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Meet Student',
            'email' => 'meet-student-'.uniqid().'@excellenteducators.test',
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
            'name' => 'Meet Student Two',
            'email' => 'meet-student-2-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '97'.random_int(10000000, 99999999),
            'class_grade' => 6,
        ])->assertCreated()->json('data.id');

        return StudentProfile::query()->with('user')->findOrFail($id);
    }

    private function completeIntroduction(StudentProfile $student, TeacherProfile $teacher): void
    {
        $booking = $this->book($student, $teacher, 'introduction_call', '2026-09-16', '06:00');
        $booking->update([
            'status' => SessionBookingStatus::Completed->value,
            'ends_at' => Carbon::parse('2026-09-15 07:00:00', 'Asia/Kolkata'),
        ]);
    }

    private function book(StudentProfile $student, TeacherProfile $teacher, string $type, string $date, string $start): SessionBooking
    {
        $id = $this->withToken($this->tokenFor($student->user))->postJson('/api/v1/student/bookings', [
            'teacher_id' => $teacher->id,
            'type' => $type,
            'date' => $date,
            'start' => $start,
        ])->assertCreated()->json('data.id');

        return SessionBooking::query()->findOrFail($id);
    }

    private function latestBookingId(StudentProfile $student): string
    {
        return SessionBooking::query()->where('student_id', $student->id)->latest()->firstOrFail()->id;
    }

    private function makeAdmin(): User
    {
        $user = User::factory()->create(['email' => 'ops-meet-'.uniqid().'@excellenteducators.test']);
        $user->assignRole(RoleName::OperationalAdmin->value);

        return $user;
    }

    private function makeMasterTeacher(): TeacherProfile
    {
        $user = User::factory()->create(['email' => 'mt-meet-'.uniqid().'@excellenteducators.test']);
        $user->assignRole(RoleName::MasterTeacher->value);
        $profile = TeacherProfile::query()->create([
            'user_id' => $user->id,
            'full_name' => $user->name,
            'status' => 'active',
        ]);
        $profile->setRelation('user', $user);

        return $profile;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('test')->plainTextToken;
    }
}
