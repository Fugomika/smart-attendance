<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['UserId', 'OfficeId', 'attendanceDate', 'clockInTime', 'clockOutTime', 'clockInLat', 'clockInLng', 'isOutside', 'outsideReason', 'clockInPhotoId', 'status'])]
class Attendance extends Model
{
    use HasUuids;

    protected $keyType = 'string';

    public $incrementing = false;

    protected $casts = [
        'attendanceDate' => 'date:Y-m-d',
        'clockInTime' => 'datetime',
        'clockOutTime' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'UserId');
    }

    public function office(): BelongsTo
    {
        return $this->belongsTo(Office::class, 'OfficeId');
    }

    public function photo(): BelongsTo
    {
        return $this->belongsTo(File::class, 'clockInPhotoId');
    }

    public function logs(): HasMany
    {
        return $this->hasMany(AttendanceLog::class, 'AttendanceId');
    }

    public function latestRejectedLog(): HasOne
    {
        return $this->hasOne(AttendanceLog::class, 'AttendanceId')
            ->where('statusAfter', 'REJECTED')
            ->latestOfMany();
    }
}
