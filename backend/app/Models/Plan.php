<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plan extends Model
{
    use HasFactory;

    protected $fillable = [
        'circle_id',
        'created_by',
        'title',
        'description',
        'event_type',
        'start_at',
        'end_at',
        'timezone',
        'status',
    ];

    protected $casts = [
        'start_at' => 'datetime',
        'end_at' => 'datetime',
    ];

    public function circle(): BelongsTo
    {
        return $this->belongsTo(Circle::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function members(): HasMany
    {
        return $this->hasMany(PlanMember::class);
    }

    public function options(): HasMany
    {
        return $this->hasMany(PlanOption::class);
    }

    public function locations(): HasMany
    {
        return $this->hasMany(PlanLocation::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(PlanMessage::class);
    }
}
