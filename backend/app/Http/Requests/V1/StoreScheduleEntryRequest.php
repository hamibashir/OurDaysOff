<?php

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

class StoreScheduleEntryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'shift_template_id' => ['nullable', 'exists:shift_templates,id'],
            'date' => ['required', 'date_format:Y-m-d'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i'],
            'entry_type' => ['required', 'string', 'in:work,personal,leave,off,other'],
            'label' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'is_overnight' => ['nullable', 'boolean'],
            'source' => ['nullable', 'string', 'in:manual,template,import'],
        ];
    }
}
