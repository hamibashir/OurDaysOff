<?php

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->user()->id;

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'handle' => ['sometimes', 'nullable', 'string', 'max:30', 'regex:/^[a-zA-Z0-9_]+$/', Rule::unique('users', 'handle')->ignore($userId)],
            'handle_visibility' => ['sometimes', 'required', 'string', Rule::in(['public', 'circle_only', 'private'])],
        ];
    }
}
