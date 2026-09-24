<?php

namespace Tests\Feature\Api\V1;

use App\Models\StudentProfile;
use Database\Seeders\RoleSeeder;
use Database\Seeders\SitePageSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SitePageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, SitePageSeeder::class]);
    }

    public function test_public_can_list_and_view_site_pages(): void
    {
        $this->getJson('/api/v1/site-pages')
            ->assertOk()
            ->assertJsonCount(4, 'data')
            ->assertJsonPath('data.0.slug', 'privacy-policy');

        $this->getJson('/api/v1/site-pages/privacy-policy')
            ->assertOk()
            ->assertJsonPath('data.title', 'Privacy Policy')
            ->assertJsonPath('data.slug', 'privacy-policy');

        $this->getJson('/api/v1/site-pages/unknown')
            ->assertNotFound();
    }

    public function test_admin_can_update_site_page(): void
    {
        $admin = $this->makeAdmin();
        $token = $this->tokenFor($admin);

        $this->withToken($token)->putJson('/api/v1/admin/site-pages/contact', [
            'title' => 'Contact Excellent Educators',
            'body' => "Email us at Excellenteducator555@gmail.com\nPhone +91 85589 51555",
        ])
            ->assertOk()
            ->assertJsonPath('data.title', 'Contact Excellent Educators');

        $this->getJson('/api/v1/site-pages/contact')
            ->assertOk()
            ->assertJsonPath('data.title', 'Contact Excellent Educators');
    }

    public function test_student_cannot_update_site_page(): void
    {
        $admin = $this->makeAdmin();
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Policy Student',
            'email' => 'policy-student-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        $student = StudentProfile::query()->with('user')->findOrFail($id);

        $this->withToken($this->tokenFor($student->user))->putJson('/api/v1/admin/site-pages/contact', [
            'title' => 'Hacked',
            'body' => 'No',
        ])->assertForbidden();
    }
}
