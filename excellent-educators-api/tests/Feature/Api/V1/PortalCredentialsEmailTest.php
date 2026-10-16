<?php

namespace Tests\Feature\Api\V1;

use App\Mail\PortalCredentialsMail;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PortalCredentialsEmailTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
        config(['app.frontend_url' => 'https://portal.excellenteducators.in']);
    }

    public function test_student_create_can_email_temporary_password(): void
    {
        Mail::fake();
        $admin = $this->makeAdmin();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Mail Student',
            'email' => 'mail-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '97'.random_int(10000000, 99999999),
            'class_grade' => 6,
            'gender' => 'male',
            'send_password_email' => true,
        ])->assertCreated();

        Mail::assertSent(PortalCredentialsMail::class, function (PortalCredentialsMail $mail) {
            return $mail->hasTo('mail-student@excellenteducators.test')
                && $mail->context['role_label'] === 'Student'
                && $mail->context['temporary_password'] === 'StudentPass1!'
                && $mail->context['login_url'] === 'https://portal.excellenteducators.in/#/login'
                && filled($mail->context['student_code'] ?? null);
        });
    }

    public function test_student_create_skips_email_when_unchecked(): void
    {
        Mail::fake();
        $admin = $this->makeAdmin();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Quiet Student',
            'email' => 'quiet-student@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '97'.random_int(10000000, 99999999),
            'class_grade' => 7,
            'gender' => 'female',
            'send_password_email' => false,
        ])->assertCreated();

        Mail::assertNothingSent();
    }

    public function test_teacher_and_sub_admin_create_can_email_credentials(): void
    {
        Mail::fake();
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $this->withToken($token)->postJson('/api/v1/admin/teachers', [
            'name' => 'Mail Teacher',
            'gender' => 'female',
            'email' => 'mail-teacher@excellenteducators.test',
            'password' => 'TeacherPass1!',
            'send_password_email' => true,
        ])->assertCreated();

        $this->withToken($token)->postJson('/api/v1/admin/sub-admins', [
            'name' => 'Mail Sub',
            'email' => 'mail-sub@excellenteducators.test',
            'password' => 'SubAdminPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'gender' => 'male',
            'send_password_email' => true,
        ])->assertCreated();

        Mail::assertSent(PortalCredentialsMail::class, fn (PortalCredentialsMail $mail) => $mail->hasTo('mail-teacher@excellenteducators.test')
            && $mail->context['role_label'] === 'Teacher');

        Mail::assertSent(PortalCredentialsMail::class, fn (PortalCredentialsMail $mail) => $mail->hasTo('mail-sub@excellenteducators.test')
            && $mail->context['role_label'] === 'Sub Admin');
    }
}
