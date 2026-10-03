<?php

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCircleMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'role' => ['sometimes', 'required', 'string', 'in:owner,admin,member'],
            'member_type' => ['sometimes', 'required', 'string', 'in:working,viewer'],
            'visibility' => ['sometimes', 'required', 'string', 'in:free_busy,shifts,details'],
            'status' => ['sometimes', 'required', 'string', 'in:pending,active,removed'],
        ];
    }
}
