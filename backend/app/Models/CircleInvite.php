<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CircleInvite extends Model
{
    use HasFactory;

    protected $fillable = [
        'circle_id',
        'created_by',
        'invite_code',
        'expires_at',
        'max_uses',
        'uses',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function circle(): BelongsTo
    {
        return $this->belongsTo(Circle::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
