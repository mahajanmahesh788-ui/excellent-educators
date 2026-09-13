<?php

namespace App\Models;

use App\Enums\JoinActorType;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClassJoinEvent extends Model
{
    use HasUlids;

    protected $fillable = [
        'booking_id',
        'actor_type',
        'actor_id',
        'joined_at',
    ];

    protected function casts(): array
    {
        return [
            'actor_type' => JoinActorType::class,
            'joined_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(SessionBooking::class, 'booking_id');
    }
}
