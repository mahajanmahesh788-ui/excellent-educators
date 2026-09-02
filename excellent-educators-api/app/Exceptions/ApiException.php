<?php

namespace App\Exceptions;

use Symfony\Component\HttpKernel\Exception\HttpException;

class ApiException extends HttpException
{
    public function __construct(
        public readonly string $errorCode,
        string $message,
        int $status = 400,
        public readonly mixed $details = null,
    ) {
        parent::__construct($status, $message);
    }
}
