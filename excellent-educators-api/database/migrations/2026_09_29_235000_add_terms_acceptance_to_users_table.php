<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('terms_accepted_at')->nullable()->after('last_login_at');
            $table->string('terms_accepted_version', 32)->nullable()->after('terms_accepted_at');
            $table->string('terms_accepted_ip', 45)->nullable()->after('terms_accepted_version');
            $table->text('terms_accepted_user_agent')->nullable()->after('terms_accepted_ip');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'terms_accepted_at',
                'terms_accepted_version',
                'terms_accepted_ip',
                'terms_accepted_user_agent',
            ]);
        });
    }
};
