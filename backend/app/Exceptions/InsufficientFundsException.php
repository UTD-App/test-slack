<?php

namespace App\Exceptions;

use RuntimeException;

class InsufficientFundsException extends RuntimeException
{
    public function __construct(
        public readonly string $currency = 'coins',
        public readonly float $required = 0,
        public readonly float $available = 0,
        string $message = '',
    ) {
        parent::__construct($message ?: "Insufficient {$currency}: needs {$required}, has {$available}.");
    }
}
