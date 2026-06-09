<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['AttendanceId', 'ActorId', 'statusBefore', 'statusAfter', 'note'])]
class AttendanceLog extends Model
{
    use HasUuids;

    protected $keyType = 'string';

    public $incrementing = false;

    public function attendance(): BelongsTo
    {
        return $this->belongsTo(Attendance::class, 'AttendanceId');
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'ActorId');
    }
}
