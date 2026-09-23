<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin_activity_events', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('actor_id')->constrained('users')->cascadeOnDelete();
            $table->string('type');
            $table->string('message');
            $table->timestamp('occurred_at');
            $table->string('related_type')->nullable();
            $table->ulid('related_id')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['actor_id', 'occurred_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_activity_events');
    }
};
