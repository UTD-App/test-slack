<?php

namespace App\Exceptions;

use App\Helpers\Common;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontReport = [
        ValidationException::class,
    ];

    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function render($request, Throwable $e): \Illuminate\Http\Response|\Illuminate\Http\JsonResponse|\Illuminate\Http\RedirectResponse|\Symfony\Component\HttpFoundation\Response
    {
        if ($request->is('api/*')) {
            if ($e instanceof CValidationException) {
                $statusCode = method_exists($e, 'getStatusCode') ? $e->getStatusCode() : 422;
                return Common::apiResponse(false, $e->getMessage(), null, $statusCode);
            }

            // A plain Laravel ValidationException (from $request->validate() /
            // Validator::validate()) would otherwise fall through to the 500
            // fallback below on api/* routes. Render it as a proper 422 with the
            // field errors — one systemic fix for every `$request->validate()`
            // call instead of rewriting each into CValidationException.
            if ($e instanceof ValidationException) {
                return Common::apiResponse(
                    false,
                    $e->validator->errors()->first(),
                    $e->errors(),
                    422,
                );
            }

            if ($e instanceof MediaUploadException) {
                return Common::apiResponse(false, $e->getMessage(), null, $e->getStatusCode());
            }

            if ($e instanceof AuthenticationException) {
                return Common::apiResponse(false, 'Unauthenticated', [], 401);
            }

            if ($e instanceof ModelNotFoundException) {
                return Common::apiResponse(false, 'Wrong passed data', [], 422);
            }

            if ($e instanceof HttpException) {
                $statusCode = $e->getStatusCode();
                if ($statusCode < 100 || $statusCode > 599) {
                    $statusCode = 500;
                }

                if ($statusCode === 429) {
                    $retryAfter = $e->getHeaders()['Retry-After'] ?? null;
                    $data = $retryAfter ? ['retry_after' => $retryAfter] : null;
                    return Common::apiResponse(false, __('api_responses.too_many_requests'), $data, 429);
                }

                return Common::apiResponse(false, $e->getMessage(), null, $statusCode);
            }

            return Common::apiResponse(false, $e->getMessage(), null, 500);
        }

        return parent::render($request, $e);
    }

    public function register()
    {
        $this->reportable(function (Throwable $e) {
            //
        });

        $this->renderable(function (AuthenticationException $e, $request) {
            if ($request->is('api/*')) {
                return Common::apiResponse(false, 'Unauthenticated', [], 401);
            }
        });
    }
}
