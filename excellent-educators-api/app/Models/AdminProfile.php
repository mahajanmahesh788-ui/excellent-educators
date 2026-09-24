<?php

namespace App\Models;

use App\Enums\AdminAccountType;
use App\Enums\Gender;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class AdminProfile extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'user_id',
        'phone',
        'gender',
        'type',
    ];

    protected function casts(): array
    {
        return [
            'gender' => Gender::class,
            'type' => AdminAccountType::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isAgent(): bool
    {
        return ($this->type ?? AdminAccountType::Admin)->isAgent();
    }
}
