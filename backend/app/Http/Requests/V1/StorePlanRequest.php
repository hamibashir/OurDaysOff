<?php

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

class StorePlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'circle_id' => ['required', 'exists:circles,id'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'event_type' => ['required', 'string', 'in:social,meal,travel,other'],
            'start_at' => ['nullable', 'date'],
            'end_at' => ['nullable', 'date'],
            'status' => ['nullable', 'string', 'in:draft,polling,confirmed'],
        ];
    }
}
