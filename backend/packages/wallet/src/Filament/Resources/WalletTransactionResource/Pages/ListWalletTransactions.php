<?php

namespace Utd\Wallet\Filament\Resources\WalletTransactionResource\Pages;

use Filament\Resources\Components\Tab;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Database\Eloquent\Builder;
use Utd\Wallet\Filament\Resources\WalletTransactionResource;

class ListWalletTransactions extends ListRecords
{
    protected static string $resource = WalletTransactionResource::class;

    /**
     * Split the ledger by currency into top tabs so coins and diamonds are never
     * mixed. Coins are this package's; the Diamond tab fills once the agency
     * package writes diamond movements (currency = 'diamonds').
     */
    public function getTabs(): array
    {
        return [
            'coins' => Tab::make(__('wallet::admin.tab_coins'))
                ->modifyQueryUsing(fn (Builder $query) => $query->where('currency', 'coins')),
            'diamonds' => Tab::make(__('wallet::admin.tab_diamonds'))
                ->modifyQueryUsing(fn (Builder $query) => $query->where('currency', 'diamonds')),
        ];
    }
}
