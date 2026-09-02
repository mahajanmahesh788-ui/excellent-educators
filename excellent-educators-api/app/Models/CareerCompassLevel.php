<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CareerCompassLevel extends Model
{
    use HasUlids;

    protected $fillable = [
        'code',
        'name',
        'class_from',
        'class_to',
    ];

    protected function casts(): array
    {
        return [
            'class_from' => 'integer',
            'class_to' => 'integer',
        ];
    }

    public function batches(): HasMany
    {
        return $this->hasMany(Batch::class);
    }

    public function students(): HasMany
    {
        return $this->hasMany(StudentProfile::class);
    }
}
