<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ScheduleEntry extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'shift_template_id',
        'date',
        'start_time',
        'end_time',
        'timezone',
        'entry_type',
        'label',
        'notes',
        'is_overnight',
        'source',
    ];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'is_overnight' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function shiftTemplate(): BelongsTo
    {
        return $this->belongsTo(ShiftTemplate::class);
    }
}
