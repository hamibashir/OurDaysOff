<?php

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

class StoreCircleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'handle' => ['nullable', 'string', 'max:30', 'regex:/^[a-zA-Z0-9_]+$/', 'unique:circles,handle'],
            'discoverability' => ['required', 'string', 'in:private,searchable'],
        ];
    }
}
