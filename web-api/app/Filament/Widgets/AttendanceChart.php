<?php

namespace App\Filament\Widgets;

use App\Models\Attendance;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Carbon;

class AttendanceChart extends ChartWidget
{
    protected ?string $heading = 'Tren Absensi (30 Hari Terakhir)';

    protected static ?int $sort = 3;

    protected function getData(): array
    {
        $days = collect(range(29, 0))->map(fn ($i) => Carbon::today()->subDays($i));

        $valid = $days->map(fn ($date) => Attendance::whereDate('attendanceDate', $date)
            ->where('status', 'VALID')->count()
        );

        $pending = $days->map(fn ($date) => Attendance::whereDate('attendanceDate', $date)
            ->where('status', 'PENDING')->count()
        );

        $rejected = $days->map(fn ($date) => Attendance::whereDate('attendanceDate', $date)
            ->where('status', 'REJECTED')->count()
        );

        return [
            'datasets' => [
                [
                    'label' => 'Valid',
                    'data' => $valid->values()->all(),
                    'borderColor' => '#22c55e',
                    'backgroundColor' => 'rgba(34,197,94,0.1)',
                    'tension' => 0.3,
                    'fill' => true,
                ],
                [
                    'label' => 'Pending',
                    'data' => $pending->values()->all(),
                    'borderColor' => '#f59e0b',
                    'backgroundColor' => 'rgba(245,158,11,0.1)',
                    'tension' => 0.3,
                    'fill' => true,
                ],
                [
                    'label' => 'Ditolak',
                    'data' => $rejected->values()->all(),
                    'borderColor' => '#ef4444',
                    'backgroundColor' => 'rgba(239,68,68,0.1)',
                    'tension' => 0.3,
                    'fill' => true,
                ],
            ],
            'labels' => $days->map(fn ($date) => $date->format('d M'))->all(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
