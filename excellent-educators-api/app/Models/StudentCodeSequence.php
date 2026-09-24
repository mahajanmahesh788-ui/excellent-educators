<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentCodeSequence extends Model
{
    public $incrementing = false;

    public $timestamps = false;

    protected $primaryKey = null;

    protected $fillable = [
        'campaign_code',
        'academic_year',
        'month',
        'last_seq',
    ];

    protected function casts(): array
    {
        return [
            'academic_year' => 'integer',
            'month' => 'integer',
            'last_seq' => 'integer',
        ];
    }
}
