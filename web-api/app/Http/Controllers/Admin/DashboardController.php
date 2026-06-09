<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponse;
use App\Models\Attendance;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    use ApiResponse;

    public function summary(Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'sometimes|date_format:Y-m-d',
        ]);

        $date = $request->get('date', Carbon::today('Asia/Jakarta')->toDateString());
        $total = User::where('status', 'ACTIVE')->count();
        $attendance = Attendance::query()->whereDate('attendanceDate', $date);

        $recorded = (clone $attendance)
            ->whereHas('user', fn ($query) => $query->where('status', 'ACTIVE'))
            ->count();

        return $this->success('Data retrieved successfully', [
            'date' => $date,
            'total' => $total,
            'present' => (clone $attendance)->whereHas('user', fn ($query) => $query->where('status', 'ACTIVE'))->where('status', 'VALID')->count(),
            'pending' => (clone $attendance)->whereHas('user', fn ($query) => $query->where('status', 'ACTIVE'))->whereIn('status', ['CHECKED_IN', 'PENDING'])->count(),
            'absent' => $total - $recorded,
            'others' => (clone $attendance)->whereHas('user', fn ($query) => $query->where('status', 'ACTIVE'))->whereIn('status', ['SICK', 'LEAVE', 'HOLIDAY', 'REJECTED'])->count(),
        ]);
    }
}
