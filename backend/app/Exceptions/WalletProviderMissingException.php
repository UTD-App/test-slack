<?php

namespace App\Exceptions;

use RuntimeException;

class WalletProviderMissingException extends RuntimeException
{
    public function __construct(string $message = 'No wallet provider installed. Install a Wallet package to enable balance operations.')
    {
        parent::__construct($message);
    }
}
