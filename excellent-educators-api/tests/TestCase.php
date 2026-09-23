<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Tests\Concerns\CreatesActors;

abstract class TestCase extends BaseTestCase
{
    use CreatesActors;
}
