<?php

namespace App\Http\Traits;

use App\Models\Attendance;
use App\Models\File;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;

trait ApiResponse
{
    protected function success(string $message, mixed $data = null, int $status = 200): JsonResponse
    {
        return response()->json(['message' => $message, 'data' => $data], $status);
    }

    protected function paginate(string $message, LengthAwarePaginator $paginator, callable $transform): JsonResponse
    {
        return response()->json([
            'message' => $message,
            'data' => [
                'count' => $paginator->total(),
                'records' => $paginator->getCollection()->map($transform)->values(),
                'page' => $paginator->currentPage(),
                'pageSize' => $paginator->perPage(),
                'pageNum' => $paginator->lastPage(),
            ],
        ]);
    }

    protected function fileUrl(File $file): string
    {
        return Storage::disk('public')->url($file->objectKey);
    }

    protected function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role,
            'jabatan' => $user->jabatan,
            'status' => $user->status,
            'photoUrl' => $user->photo ? $this->fileUrl($user->photo) : null,
        ];
    }

    protected function formatFile(File $file): array
    {
        return [
            'id' => $file->id,
            'originalName' => $file->originalName,
            'contentType' => $file->contentType,
            'context' => $file->context,
            'url' => $this->fileUrl($file),
            'status' => $file->status,
            'createdAt' => $this->wib($file->created_at),
        ];
    }

    protected function formatAttendanceSummary(Attendance $att): array
    {
        return [
            'id' => $att->id,
            'attendanceDate' => $att->attendanceDate?->format('Y-m-d'),
            'status' => $att->status,
            'clockInTime' => $this->wib($att->clockInTime),
            'clockOutTime' => $this->wib($att->clockOutTime),
            'isOutside' => (bool) $att->isOutside,
            'officeName' => $att->office?->officeName,
        ];
    }

    protected function formatAttendanceToday(Attendance $att): array
    {
        return [
            'id' => $att->id,
            'attendanceDate' => $att->attendanceDate?->format('Y-m-d'),
            'status' => $att->status,
            'clockInTime' => $this->wib($att->clockInTime),
            'clockOutTime' => $this->wib($att->clockOutTime),
            'clockInLat' => $att->clockInLat !== null ? (float) $att->clockInLat : null,
            'clockInLng' => $att->clockInLng !== null ? (float) $att->clockInLng : null,
            'isOutside' => (bool) $att->isOutside,
            'outsideReason' => $att->outsideReason,
            'officeId' => $att->getAttribute('OfficeId'),
            'officeName' => $att->office?->officeName,
            'selfieUrl' => $att->photo ? $this->fileUrl($att->photo) : null,
        ];
    }

    protected function formatAttendanceDetail(Attendance $att): array
    {
        return array_merge($this->formatAttendanceToday($att), [
            'createdAt' => $this->wib($att->created_at),
            'updatedAt' => $this->wib($att->updated_at),
        ]);
    }

    private function wib(?Carbon $dt): ?string
    {
        return $dt?->setTimezone('Asia/Jakarta')->format('Y-m-d\TH:i:sP');
    }
}
