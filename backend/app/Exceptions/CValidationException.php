<?php

namespace App\Exceptions;

use Exception;

class CValidationException extends Exception
{
    public function getStatusCode(): int
    {
        return 422;
    }
}
