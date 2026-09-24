<?php

namespace App\Models;

use App\Enums\PermissionName;
use App\Enums\RoleName;
use App\Enums\UserStatus;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

#[Fillable(['name', 'email', 'password', 'status', 'last_login_at'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, HasUlids, Notifiable, SoftDeletes;

    protected string $guard_name = 'web';

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'password' => 'hashed',
            'status' => UserStatus::class,
        ];
    }

    public function isActive(): bool
    {
        return $this->status === UserStatus::Active;
    }

    public function studentProfile(): HasOne
    {
        return $this->hasOne(StudentProfile::class);
    }

    public function teacherProfile(): HasOne
    {
        return $this->hasOne(TeacherProfile::class);
    }

    public function isAdmin(): bool
    {
        return $this->hasAnyRole([
            RoleName::SuperAdmin->value,
            RoleName::OperationalAdmin->value,
            RoleName::SubAdmin->value,
        ]);
    }

    public function isFullAdmin(): bool
    {
        return $this->hasAnyRole([
            RoleName::SuperAdmin->value,
            RoleName::OperationalAdmin->value,
        ]);
    }

    public function isSubAdmin(): bool
    {
        return $this->hasRole(RoleName::SubAdmin->value);
    }

    public function isAgent(): bool
    {
        return $this->isSubAdmin() && ($this->adminProfile?->isAgent() ?? false);
    }

    public function canAdmin(PermissionName $permission): bool
    {
        if ($this->isFullAdmin()) {
            return true;
        }

        return $this->can($permission->value);
    }

    public function adminProfile(): HasOne
    {
        return $this->hasOne(AdminProfile::class);
    }
}
