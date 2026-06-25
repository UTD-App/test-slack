<?php

namespace Utd\Wallet\Http\Controllers;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Utd\Wallet\Models\Coin;
use Utd\Wallet\Models\PaymentCoin;

/**
 * Read-only coin catalogue for the recharge screen: the purchasable coin
 * packages and the payment package groups they belong to. The actual purchase
 * (gateway + crediting the wallet) is handled by the payment package, which
 * credits coins through the Wallet facade on a successful payment.
 */
class CoinController extends Controller
{
    /** Coin packages for purchase, optionally filtered by payment group. */
    public function coins(Request $request)
    {
        $coins = Coin::query()
            ->when($request->filled('payment_gateway_id'),
                fn ($q) => $q->where('payment_gateway_id', $request->integer('payment_gateway_id')))
            ->orderBy('sort')
            ->orderBy('usd')
            ->get();

        return Common::apiResponse(true, 'coins', $coins);
    }

    /** Active payment package groups (user | shipping_agency), optionally by type. */
    public function paymentMethods(Request $request)
    {
        $methods = PaymentCoin::active()
            ->when($request->filled('type'),
                fn ($q) => $q->where('type', $request->string('type')->toString()))
            ->where('package_type', $request->string('package_type')->toString() ?: 'user')
            ->get();

        return Common::apiResponse(true, 'payment_methods', $methods);
    }
}
