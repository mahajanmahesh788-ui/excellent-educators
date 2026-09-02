<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('login_page_contents', function (Blueprint $table): void {
            $table->ulid('id')->primary();
            $table->string('tagline');
            $table->string('headline');
            $table->text('description');
            $table->json('pillars');
            $table->text('mission_quote')->nullable();
            $table->string('form_title');
            $table->text('form_subtitle');
            $table->string('forgot_form_title');
            $table->text('forgot_form_subtitle');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('login_page_contents');
    }
};
