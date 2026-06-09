<?php

namespace App\Support\Wallet;

/**
 * Outcome of a wallet credit/debit operation.
 */
class WalletResult
{
    public function __construct(
        public readonly bool $success,
        public readonly string $currency,
        public readonly float $amount,
        public readonly float $balance,
        public readonly string $reason,
        public readonly ?string $transactionId = null,
        public readonly array $meta = [],
    ) {
    }

    public function toArray(): array
    {
        return [
            'success'        => $this->success,
            'currency'       => $this->currency,
            'amount'         => $this->amount,
            'balance'        => $this->balance,
            'reason'         => $this->reason,
            'transaction_id' => $this->transactionId,
            'meta'           => $this->meta,
        ];
    }
}
