<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('generated_bills', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('bill_number', 40)->unique();
            $table->string('full_name');
            $table->string('email')->nullable();
            $table->string('phone', 32);
            $table->string('whatsapp_number', 32)->nullable();
            $table->string('address', 1000)->nullable();
            $table->unsignedTinyInteger('class_grade');
            $table->string('gender', 20);
            $table->string('guardian_name')->nullable();
            $table->string('guardian_phone', 32)->nullable();
            $table->string('payment_type', 20); // full | partial
            $table->string('payment_mode', 20)->default('offline'); // online | offline
            $table->decimal('total_amount', 12, 2);
            $table->decimal('paid_amount', 12, 2)->default(0);
            $table->string('notes', 2000)->nullable();
            $table->date('bill_date');
            $table->foreignUlid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['bill_date', 'created_at']);
            $table->index('full_name');
            $table->index('phone');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('generated_bills');
    }
};
