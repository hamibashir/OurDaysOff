<?php

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

class ConfirmImportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'entries' => ['required', 'array', 'min:1'],
            'entries.*.date' => ['required', 'date_format:Y-m-d'],
            'entries.*.start_time' => ['required', 'date_format:H:i'],
            'entries.*.end_time' => ['required', 'date_format:H:i'],
            'entries.*.entry_type' => ['nullable', 'string'],
            'entries.*.label' => ['nullable', 'string', 'max:255'],
            'entries.*.shift_label' => ['nullable', 'string', 'max:255'],
            'entries.*.is_overnight' => ['nullable', 'boolean'],
        ];
    }
}
