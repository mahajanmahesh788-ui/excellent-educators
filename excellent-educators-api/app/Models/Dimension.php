<?php

namespace App\Models;

use App\Enums\DimensionCode;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Dimension extends Model
{
    use HasUlids;

    protected $fillable = [
        'code',
        'name',
        'display_order',
    ];

    protected function casts(): array
    {
        return [
            'code' => DimensionCode::class,
            'display_order' => 'integer',
        ];
    }

    public function modules(): HasMany
    {
        return $this->hasMany(DevelopmentModule::class);
    }
}
