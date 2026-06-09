<?php

namespace App\Http\Controllers;

use App\Http\Traits\ApiResponse;
use App\Models\Attendance;
use App\Models\File;
use App\Models\Office;
use App\Services\AttendanceTransitionService;
use DomainException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class AttendanceController extends Controller
{
    use ApiResponse;

    public function today(Request $request): JsonResponse
    {
        $today = Carbon::today('Asia/Jakarta')->toDateString();

        $att = Attendance::with(['office', 'photo'])
            ->where('UserId', $request->user()->id)
            ->whereDate('attendanceDate', $today)
            ->first();

        return $this->success('Data retrieved successfully', $att ? $this->formatAttendanceToday($att) : null);
    }

    public function history(Request $request): JsonResponse
    {
        $request->validate([
            'page' => 'sometimes|integer|min:1',
            'pageSize' => 'sometimes|integer|min:1|max:100',
            'month' => 'sometimes|date_format:Y-m',
            'sortOrder' => 'sometimes|in:ASC,DESC',
        ]);

        $query = Attendance::with('office')
            ->where('UserId', $request->user()->id);

        if ($request->filled('month')) {
            $start = Carbon::createFromFormat('Y-m', $request->month)->startOfMonth()->toDateString();
            $end = Carbon::createFromFormat('Y-m', $request->month)->endOfMonth()->toDateString();
            $query->whereBetween('attendanceDate', [$start, $end]);
        }

        $order = strtoupper($request->get('sortOrder', 'DESC'));
        $query->orderBy('attendanceDate', $order);

        $pageSize = (int) $request->get('pageSize', 10);
        $paginator = $query->paginate($pageSize, ['*'], 'page', $request->get('page', 1));

        return $this->paginate('Data retrieved successfully', $paginator, fn ($att) => $this->formatAttendanceSummary($att));
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $att = Attendance::with(['office', 'photo', 'latestRejectedLog'])->find($id);

        if (! $att) {
            return response()->json(['message' => 'Not found'], 404);
        }

        if ($att->getAttribute('UserId') !== $request->user()->id) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        return $this->success('Data retrieved successfully', $this->formatAttendanceDetail($att));
    }

    public function clockIn(Request $request, AttendanceTransitionService $transitionService): JsonResponse
    {
        $request->validate([
            'officeId' => 'required|uuid',
            'clockInLat' => 'required|numeric|between:-90,90',
            'clockInLng' => 'required|numeric|between:-180,180',
            'isOutside' => 'required|boolean',
            'outsideReason' => 'nullable|string|max:255',
            'clockInPhotoId' => 'required|uuid',
        ]);

        $user = $request->user();
        $today = Carbon::today('Asia/Jakarta')->toDateString();

        if (Attendance::where('UserId', $user->id)->whereDate('attendanceDate', $today)->exists()) {
            return response()->json(['message' => 'Attendance already recorded today'], 409);
        }

        $office = Office::where('id', $request->officeId)->where('isActive', true)->first();
        if (! $office) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $photo = File::where('id', $request->clockInPhotoId)
            ->where('UserId', $user->id)
            ->where('context', 'attendance_selfie')
            ->first();
        if (! $photo) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $distance = $this->haversine(
            (float) $request->clockInLat,
            (float) $request->clockInLng,
            (float) $office->latitude,
            (float) $office->longitude
        );

        $isOutside = $distance > $office->radiusMeter;

        if ($isOutside && ! filled($request->outsideReason)) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => [['path' => 'outsideReason', 'message' => 'Outside reason is required when location is outside office radius']],
            ], 422);
        }

        $att = $transitionService->create(
            fn (): Attendance => Attendance::create([
                'UserId' => $user->id,
                'OfficeId' => $office->id,
                'attendanceDate' => $today,
                'clockInTime' => now(),
                'clockInLat' => $request->clockInLat,
                'clockInLng' => $request->clockInLng,
                'isOutside' => $isOutside,
                'outsideReason' => $isOutside ? $request->outsideReason : null,
                'clockInPhotoId' => $photo->id,
                'status' => 'CHECKED_IN',
            ]),
            $user,
            fn () => $photo->update(['status' => 'CONFIRMED']),
        );

        $att->setRelation('office', $office);
        $att->setRelation('photo', $photo);

        return $this->success('Clock in successful', $this->formatAttendanceToday($att), 201);
    }

    public function clockOut(Request $request, AttendanceTransitionService $transitionService): JsonResponse
    {
        $request->validate([
            'attendanceId' => 'required|uuid',
        ]);

        $att = Attendance::with('office')->find($request->attendanceId);

        if (! $att) {
            return response()->json(['message' => 'Not found'], 404);
        }

        if ($att->getAttribute('UserId') !== $request->user()->id) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        if ($att->status !== 'CHECKED_IN') {
            return response()->json(['message' => 'Attendance status is not CHECKED_IN'], 400);
        }

        $today = Carbon::today('Asia/Jakarta')->toDateString();
        if ($att->attendanceDate->format('Y-m-d') !== $today) {
            return response()->json(['message' => 'Attendance date is not today'], 400);
        }

        $newStatus = $att->isOutside ? 'PENDING' : 'VALID';

        try {
            $att = $transitionService->transition(
                $att,
                $newStatus,
                $request->user(),
                ['CHECKED_IN'],
                ['clockOutTime' => now()],
            );
        } catch (DomainException) {
            return response()->json(['message' => 'Attendance status is not CHECKED_IN'], 400);
        }

        $att->setRelation('office', $att->office()->first());

        return $this->success('Clock out successful', [
            'id' => $att->id,
            'attendanceDate' => $att->attendanceDate->format('Y-m-d'),
            'status' => $att->status,
            'clockInTime' => $att->clockInTime?->setTimezone('Asia/Jakarta')->format('Y-m-d\TH:i:sP'),
            'clockOutTime' => $att->clockOutTime?->setTimezone('Asia/Jakarta')->format('Y-m-d\TH:i:sP'),
            'isOutside' => (bool) $att->isOutside,
            'officeId' => $att->getAttribute('OfficeId'),
            'officeName' => $att->office?->officeName,
        ]);
    }

    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $R = 6371000;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $R * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
