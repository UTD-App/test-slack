<?php

namespace App\Http\Requests\Api\V1\Auth;

use App\Helpers\Common;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class RegisterRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'min:6'],
            'uuid' => ['nullable'],
            'iso' => ['sometimes', 'string', 'size:2'],
            'device_token' => ['sometimes'],
        ];
    }

    protected function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(
            Common::apiResponse(false, $validator->errors()->first(), $validator->errors(), 422)
        );
    }
}
