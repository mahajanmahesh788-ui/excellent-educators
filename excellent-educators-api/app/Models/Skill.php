<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Skill extends Model
{
    use HasUlids;

    protected $fillable = [
        'module_id',
        'name',
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'display_order' => 'integer',
        ];
    }

    public function module(): BelongsTo
    {
        return $this->belongsTo(DevelopmentModule::class, 'module_id');
    }
}
