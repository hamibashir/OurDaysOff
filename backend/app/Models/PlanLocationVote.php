<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PlanLocationVote extends Model
{
    use HasFactory;

    protected $fillable = [
        'plan_location_id',
        'user_id',
    ];

    public function planLocation(): BelongsTo
    {
        return $this->belongsTo(PlanLocation::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
