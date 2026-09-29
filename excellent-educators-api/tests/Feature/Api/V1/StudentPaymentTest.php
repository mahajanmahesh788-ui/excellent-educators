<?php

namespace Tests\Feature\Api\V1;

use App\Enums\PaymentPlanStatus;
use App\Enums\PaymentPlanType;
use App\Models\StudentPaymentPlan;
use App\Models\StudentProfile;
use App\Models\User;
use App\Payments\PaymentPlanService;
use Database\Seeders\CareerCompassLevelSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class StudentPaymentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, CareerCompassLevelSeeder::class]);
        Carbon::setTestNow(Carbon::parse('2026-09-15 10:00:00', 'Asia/Kolkata'));
    }

    public function test_admin_can_create_partial_plan_and_record_payments(): void
    {
        [$admin, $student] = $this->makeStudent();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/payments/students/{$student->id}/plan", [
            'payment_type' => 'partial',
            'preferred_mode' => 'offline',
            'total_amount' => 6500,
            'due_day' => 20,
            'initial_amount' => 2000,
        ])->assertCreated()
            ->assertJsonPath('data.plan.payment_type', 'partial')
            ->assertJsonPath('data.plan.paid_amount', 2000)
            ->assertJsonPath('data.plan.pending_amount', 4500);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/payments/students/{$student->id}/payments", [
            'amount' => 1500,
            'payment_mode' => 'offline',
        ])->assertCreated()
            ->assertJsonPath('data.delta.previous_pending', 4500)
            ->assertJsonPath('data.delta.new_pending', 3000);

        $plan = StudentPaymentPlan::query()->where('student_id', $student->id)->where('is_active', true)->first();
        $this->assertSame(2, $plan->payments()->count());
        $this->assertSame(3500.0, (float) $plan->paid_amount);
    }

    public function test_full_payment_marks_plan_paid_with_no_future_due(): void
    {
        [$admin, $student] = $this->makeStudent();

        $response = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/payments/students/{$student->id}/plan", [
            'payment_type' => 'full',
            'preferred_mode' => 'online',
            'total_amount' => 6000,
            'payment_amount' => 6000,
        ])->assertCreated();

        $this->assertSame('paid', $response->json('data.plan.status'));
        $this->assertSame(0, $response->json('data.plan.pending_amount'));
    }

    public function test_overdue_status_is_retained_across_months(): void
    {
        [$admin, $student] = $this->makeStudent();
        /** @var PaymentPlanService $service */
        $service = app(PaymentPlanService::class);

        $plan = $service->createForStudent($student, [
            'payment_type' => PaymentPlanType::Partial->value,
            'preferred_mode' => 'offline',
            'total_amount' => 6500,
            'due_day' => 20,
            'start_date' => '2026-01-01',
            'initial_amount' => 2000,
            'payment_date' => '2026-01-20',
        ], $admin->id);

        Carbon::setTestNow(Carbon::parse('2026-03-25 10:00:00', 'Asia/Kolkata'));
        $fresh = $service->recalculate($plan->fresh());

        $this->assertSame(PaymentPlanStatus::Overdue, $fresh->status);
        $this->assertGreaterThan(0, (float) $fresh->overdue_amount);
        $this->assertGreaterThan(0, (float) $fresh->pending_amount);
    }

    public function test_student_can_view_own_payment_plan(): void
    {
        [$admin, $student] = $this->makeStudent();
        app(PaymentPlanService::class)->createForStudent($student, [
            'payment_type' => 'full',
            'total_amount' => 6000,
            'payment_amount' => 6000,
            'payment_date' => '2026-09-15',
            'preferred_mode' => 'offline',
        ], $admin->id);

        $this->withToken($this->tokenFor($student->user))
            ->getJson('/api/v1/student/payments')
            ->assertOk()
            ->assertJsonPath('data.plan.status', 'paid');
    }

    public function test_overpayment_is_rejected(): void
    {
        [$admin, $student] = $this->makeStudent();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/payments/students/{$student->id}/plan", [
            'payment_type' => 'partial',
            'preferred_mode' => 'offline',
            'total_amount' => 6500,
            'due_day' => 20,
            'initial_amount' => 6000,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/payments/students/{$student->id}/payments", [
            'amount' => 1000,
            'payment_mode' => 'offline',
        ])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only ₹500 left. Amount cannot exceed the pending amount.');
    }

    public function test_plan_change_preserves_payment_history(): void
    {
        [$admin, $student] = $this->makeStudent();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/payments/students/{$student->id}/plan", [
            'payment_type' => 'full',
            'preferred_mode' => 'offline',
            'total_amount' => 6000,
            'payment_amount' => 3000,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/payments/students/{$student->id}/plan", [
            'payment_type' => 'partial',
            'preferred_mode' => 'offline',
            'total_amount' => 6500,
            'due_day' => 20,
            'reason' => 'Switched to partial plan',
        ])->assertCreated()
            ->assertJsonPath('data.plan.payment_type', 'partial');

        $this->assertDatabaseCount('student_payments', 1);
        $this->assertDatabaseCount('student_payment_plan_audits', 1);
    }

    public function test_settings_change_does_not_affect_existing_plans(): void
    {
        [$admin, $student] = $this->makeStudent();

        app(PaymentPlanService::class)->createForStudent($student, [
            'payment_type' => 'partial',
            'preferred_mode' => 'offline',
            'total_amount' => 6000,
            'due_day' => 20,
            'initial_amount' => 1500,
            'payment_date' => '2026-09-15',
        ], $admin->id);

        // Admin raises the default partial total in settings.
        \App\Models\AppSetting::query()->updateOrCreate(
            ['key' => \App\Payments\PaymentSettings::PARTIAL_TOTAL],
            ['value' => '7000'],
        );

        $plan = StudentPaymentPlan::query()
            ->where('student_id', $student->id)
            ->where('is_active', true)
            ->firstOrFail();

        $this->assertSame(6000.0, (float) $plan->total_amount);
        $this->assertSame(4500.0, (float) $plan->pending_amount);

        // Recalculate / overview must still use the locked plan amount.
        $fresh = app(PaymentPlanService::class)->recalculate($plan);
        $this->assertSame(6000.0, (float) $fresh->total_amount);
        $this->assertSame(4500.0, (float) $fresh->pending_amount);

        // Changing mode/type without an explicit new total must keep 6000.
        $changed = app(PaymentPlanService::class)->changePlan($plan, [
            'payment_type' => 'partial',
            'preferred_mode' => 'online',
        ], $admin->id);
        $this->assertSame(6000.0, (float) $changed->total_amount);

        // A brand-new student created after the settings change gets 7000.
        [, $newStudent] = $this->makeStudent();
        $newPlan = app(PaymentPlanService::class)->createForStudent($newStudent, [
            'payment_type' => 'partial',
            'preferred_mode' => 'offline',
            'initial_amount' => 0,
        ], $admin->id);
        $this->assertSame(7000.0, (float) $newPlan->total_amount);
    }

    /**
     * @return array{0: User, 1: StudentProfile}
     */
    private function makeStudent(): array
    {
        $admin = $this->makeAdmin();
        $id = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/students', [
            'name' => 'Pay Student '.uniqid(),
            'email' => 'pay-'.uniqid().'@excellenteducators.test',
            'password' => 'StudentPass1!',
            'phone' => '98'.random_int(10000000, 99999999),
            'class_grade' => 6,
            'gender' => 'male',
        ])->assertCreated()->json('data.id');

        return [$admin, StudentProfile::query()->with('user')->findOrFail($id)];
    }
}
