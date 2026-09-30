<?php

namespace App\Console\Commands;

use App\Enums\RoleName;
use App\Enums\UserStatus;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Validator;

class CreateAdminCommand extends Command
{
    protected $signature = 'app:create-admin
                            {--name= : Full name}
                            {--email= : Login email}
                            {--password= : Login password (min 10 characters)}
                            {--role=super_admin : super_admin or operational_admin}';

    protected $description = 'Create (or update) one admin user. Safe for first production login.';

    public function handle(): int
    {
        $name = (string) ($this->option('name') ?: $this->ask('Admin name'));
        $email = (string) ($this->option('email') ?: $this->ask('Admin email'));
        $password = (string) ($this->option('password') ?: $this->secret('Admin password'));
        $roleInput = (string) $this->option('role');

        $role = RoleName::tryFrom($roleInput);
        if ($role === null || ! in_array($role, [RoleName::SuperAdmin, RoleName::OperationalAdmin], true)) {
            $this->error('Role must be super_admin or operational_admin.');

            return self::FAILURE;
        }

        $validator = Validator::make(
            [
                'name' => $name,
                'email' => $email,
                'password' => $password,
            ],
            [
                'name' => ['required', 'string', 'min:2', 'max:120'],
                'email' => ['required', 'email', 'max:190'],
                'password' => ['required', 'string', 'min:10'],
            ],
        );

        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $error) {
                $this->error($error);
            }

            return self::FAILURE;
        }

        $existing = User::query()->where('email', $email)->first();
        if ($existing !== null && ! $this->option('no-interaction')) {
            if (! $this->confirm("User {$email} already exists. Update password/role?", false)) {
                $this->warn('Cancelled.');

                return self::SUCCESS;
            }
        } elseif ($existing !== null) {
            $this->warn("Updating existing user {$email}.");
        }

        $user = User::query()->updateOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'password' => $password,
                'status' => UserStatus::Active,
                'email_verified_at' => now(),
            ],
        );

        $user->syncRoles([$role->value]);

        $this->info("Admin ready: {$user->email} ({$role->value})");
        $this->line('Log in on the web app with that email and password.');

        return self::SUCCESS;
    }
}
