<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\AttendanceLog;
use App\Models\User;
use Closure;
use DomainException;
use Illuminate\Support\Facades\DB;

class AttendanceTransitionService
{
    public function create(
        Closure $createAttendance,
        ?User $actor,
        ?Closure $afterCreate = null,
    ): Attendance {
        return DB::transaction(function () use ($createAttendance, $actor, $afterCreate): Attendance {
            $attendance = $createAttendance();

            AttendanceLog::create([
                'AttendanceId' => $attendance->id,
                'ActorId' => $actor?->id,
                'statusBefore' => null,
                'statusAfter' => $attendance->status,
            ]);

            $afterCreate?->__invoke($attendance);

            return $attendance;
        });
    }

    /**
     * @param  array<int, string>  $allowedFrom
     * @param  array<string, mixed>  $attributes
     */
    public function transition(
        Attendance $attendance,
        string $statusAfter,
        ?User $actor,
        array $allowedFrom,
        array $attributes = [],
        ?string $note = null,
    ): Attendance {
        return DB::transaction(function () use (
            $attendance,
            $statusAfter,
            $actor,
            $allowedFrom,
            $attributes,
            $note,
        ): Attendance {
            $lockedAttendance = Attendance::query()
                ->lockForUpdate()
                ->findOrFail($attendance->id);

            $statusBefore = $lockedAttendance->status;

            if (! in_array($statusBefore, $allowedFrom, true)) {
                throw new DomainException('Attendance status transition is not allowed.');
            }

            $lockedAttendance->update([
                ...$attributes,
                'status' => $statusAfter,
            ]);

            AttendanceLog::create([
                'AttendanceId' => $lockedAttendance->id,
                'ActorId' => $actor?->id,
                'statusBefore' => $statusBefore,
                'statusAfter' => $statusAfter,
                'note' => $note,
            ]);

            return $lockedAttendance;
        });
    }
}
