<?php

namespace Tests\Unit;

use App\Actions\Identity\GenerateStudentCode;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class GenerateStudentCodeTest extends TestCase
{
    use RefreshDatabase;

    public function test_codes_include_year_month_and_reset_each_month(): void
    {
        $generator = new GenerateStudentCode;

        Carbon::setTestNow(Carbon::parse('2026-02-10 10:00:00', 'Asia/Kolkata'));
        $this->assertSame('26-02-01', $generator->execute());
        $this->assertSame('26-02-02', $generator->execute());

        Carbon::setTestNow(Carbon::parse('2026-03-01 10:00:00', 'Asia/Kolkata'));
        $this->assertSame('26-03-01', $generator->execute());

        Carbon::setTestNow();
    }
}
