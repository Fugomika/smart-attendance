<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponse;
use App\Models\Attendance;
use App\Models\User;
use App\Services\AttendanceTransitionService;
use DomainException;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

class AttendanceController extends Controller
{
    use ApiResponse;

    private const STATUSES = ['CHECKED_IN', 'PENDING', 'VALID', 'REJECTED', 'SICK', 'LEAVE', 'HOLIDAY'];

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'userId' => 'sometimes|uuid|exists:users,id',
            'month' => 'sometimes|date_format:Y-m',
            'status' => ['sometimes', Rule::in(self::STATUSES)],
            'page' => 'sometimes|integer|min:1',
            'pageSize' => 'sometimes|integer|min:1|max:100',
            'sortOrder' => 'sometimes|in:ASC,DESC',
        ]);

        $query = Attendance::with('office');

        if ($request->filled('userId')) {
            $query->where('UserId', $request->userId);
        }

        if ($request->filled('month')) {
            $start = Carbon::createFromFormat('Y-m', $request->month)->startOfMonth()->toDateString();
            $end = Carbon::createFromFormat('Y-m', $request->month)->endOfMonth()->toDateString();
            $query->whereBetween('attendanceDate', [$start, $end]);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $query->orderBy('attendanceDate', $request->get('sortOrder', 'DESC'));

        $paginator = $query->paginate(
            (int) $request->get('pageSize', 20),
            ['*'],
            'page',
            $request->get('page', 1),
        );

        return $this->paginate('Data retrieved successfully', $paginator, fn (Attendance $attendance) => $this->formatAdminAttendanceSummary($attendance));
    }

    public function report(Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'sometimes|date_format:Y-m-d',
            'query' => 'sometimes|string',
            'status' => ['sometimes', Rule::in([...self::STATUSES, 'NOT_CHECKED_IN'])],
            'page' => 'sometimes|integer|min:1',
            'pageSize' => 'sometimes|integer|min:1|max:100',
        ]);

        $date = $request->get('date', Carbon::today('Asia/Jakarta')->toDateString());
        $query = User::query()
            ->with([
                'photo',
                'attendances' => fn ($attendance) => $attendance
                    ->whereDate('attendanceDate', $date)
                    ->with('office'),
            ])
            ->where('status', 'ACTIVE');

        if ($request->filled('query')) {
            $search = $request->string('query')->toString();
            $query->where(fn ($builder) => $builder
                ->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%"));
        }

        if ($request->status === 'NOT_CHECKED_IN') {
            $query->whereDoesntHave('attendances', fn (Builder $attendance) => $attendance->whereDate('attendanceDate', $date));
        } elseif ($request->filled('status')) {
            $query->whereHas('attendances', fn (Builder $attendance) => $attendance
                ->whereDate('attendanceDate', $date)
                ->where('status', $request->status));
        }

        $paginator = $query
            ->orderBy('name')
            ->paginate(
                (int) $request->get('pageSize', 20),
                ['*'],
                'page',
                $request->get('page', 1),
            );

        return $this->paginate('Data retrieved successfully', $paginator, fn (User $user) => [
            'user' => $this->formatUser($user),
            'selectedDate' => $date,
            'attendance' => $user->attendances->first()
                ? $this->formatAdminAttendanceSummary($user->attendances->first())
                : null,
        ]);
    }

    public function show(string $id): JsonResponse
    {
        $attendance = Attendance::with([
            'office',
            'photo',
            'user.photo',
            'latestRejectedLog',
        ])->find($id);

        if (! $attendance) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return $this->success('Data retrieved successfully', $this->formatAdminAttendanceDetail($attendance));
    }

    public function validateAttendance(
        Request $request,
        string $id,
        AttendanceTransitionService $transitionService,
    ): JsonResponse {
        $request->validate([
            'status' => 'required|in:VALID,REJECTED',
            'note' => 'nullable|string|max:255',
        ]);

        $attendance = Attendance::find($id);

        if (! $attendance) {
            return response()->json(['message' => 'Not found'], 404);
        }

        try {
            $attendance = $transitionService->transition(
                $attendance,
                $request->status,
                $request->user(),
                ['PENDING'],
                note: $request->status === 'REJECTED' ? $request->note : null,
            );
        } catch (DomainException) {
            return response()->json(['message' => 'Attendance status is not PENDING'], 400);
        }

        $attendance->load([
            'office',
            'photo',
            'user.photo',
            'latestRejectedLog',
        ]);

        return $this->success('Data retrieved successfully', $this->formatAdminAttendanceDetail($attendance));
    }
}
