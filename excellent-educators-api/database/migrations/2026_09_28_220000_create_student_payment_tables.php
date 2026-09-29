<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('student_payment_plans', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->string('payment_type', 20); // full | partial
            $table->decimal('total_amount', 12, 2);
            $table->decimal('paid_amount', 12, 2)->default(0);
            $table->decimal('pending_amount', 12, 2)->default(0);
            $table->decimal('advance_amount', 12, 2)->default(0);
            $table->decimal('installment_amount', 12, 2)->nullable();
            $table->unsignedTinyInteger('due_day')->nullable();
            $table->date('start_date')->nullable();
            $table->date('next_due_date')->nullable();
            $table->decimal('next_due_amount', 12, 2)->nullable();
            $table->decimal('overdue_amount', 12, 2)->default(0);
            $table->date('last_payment_date')->nullable();
            $table->string('preferred_mode', 20)->nullable(); // online | offline
            $table->string('status', 20)->default('pending'); // pending | partial | paid | overdue
            $table->boolean('is_active')->default(true);
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUlid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['student_id', 'is_active']);
            $table->index(['status', 'next_due_date']);
        });

        Schema::create('student_payments', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->foreignUlid('payment_plan_id')->constrained('student_payment_plans')->cascadeOnDelete();
            $table->decimal('amount', 12, 2);
            $table->string('payment_mode', 20); // online | offline
            $table->date('payment_date');
            $table->string('transaction_id')->nullable();
            $table->string('reference_number')->nullable();
            $table->string('status', 20)->default('pending'); // pending | successful | failed | refunded
            $table->text('notes')->nullable();
            $table->string('receipt_path')->nullable();
            $table->string('gateway')->nullable();
            $table->string('gateway_order_id')->nullable()->unique();
            $table->string('gateway_payment_id')->nullable();
            $table->json('gateway_payload')->nullable();
            $table->boolean('applies_to_dues')->default(true);
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['student_id', 'payment_date']);
            $table->index(['payment_plan_id', 'status']);
            $table->index(['transaction_id']);
        });

        Schema::create('student_payment_plan_audits', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('student_id')->constrained('student_profiles')->cascadeOnDelete();
            $table->foreignUlid('payment_plan_id')->nullable()->constrained('student_payment_plans')->nullOnDelete();
            $table->string('previous_plan')->nullable();
            $table->string('new_plan')->nullable();
            $table->decimal('previous_amount', 12, 2)->nullable();
            $table->decimal('new_amount', 12, 2)->nullable();
            $table->text('reason')->nullable();
            $table->json('snapshot')->nullable();
            $table->foreignUlid('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('changed_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_payment_plan_audits');
        Schema::dropIfExists('student_payments');
        Schema::dropIfExists('student_payment_plans');
    }
};
