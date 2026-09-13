<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;

class GoogleOAuthToken extends Model
{
    use HasUlids;

    public const PURPOSE_MEET = 'meet';

    protected $table = 'google_oauth_tokens';

    protected $fillable = [
        'purpose',
        'google_email',
        'refresh_token',
        'scopes',
        'connected_at',
    ];

    protected function casts(): array
    {
        return [
            'refresh_token' => 'encrypted',
            'connected_at' => 'datetime',
        ];
    }
}
