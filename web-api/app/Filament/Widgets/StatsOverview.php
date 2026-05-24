<?php

namespace App\Filament\Widgets;

use App\Models\Attendance;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Carbon;

class StatsOverview extends StatsOverviewWidget
{
    protected function getStats(): array
    {
        $today = Carbon::today();
        $thisMonth = Carbon::now();

        $totalEmployee = User::where('role', 'EMPLOYEE')->where('status', 'ACTIVE')->count();

        $presentToday = Attendance::whereDate('attendanceDate', $today)
            ->whereIn('status', ['CHECKED_IN', 'VALID'])
            ->count();

        $pendingValidation = Attendance::where('status', 'PENDING')->count();

        $validThisMonth = Attendance::where('status', 'VALID')
            ->whereYear('attendanceDate', $thisMonth->year)
            ->whereMonth('attendanceDate', $thisMonth->month)
            ->count();

        $attendanceRate = $totalEmployee > 0
            ? round(($presentToday / $totalEmployee) * 100)
            : 0;

        return [
            Stat::make('Karyawan Aktif', $totalEmployee)
                ->description('Total karyawan terdaftar')
                ->color('info')
                ->icon('heroicon-o-users'),

            Stat::make('Hadir Hari Ini', $presentToday)
                ->description("{$attendanceRate}% dari total karyawan")
                ->color($attendanceRate >= 80 ? 'success' : ($attendanceRate >= 50 ? 'warning' : 'danger'))
                ->icon('heroicon-o-clipboard-document-check'),

            Stat::make('Menunggu Validasi', $pendingValidation)
                ->description('Absensi perlu divalidasi HR')
                ->color($pendingValidation > 0 ? 'warning' : 'success')
                ->icon('heroicon-o-clock'),

            Stat::make('Valid Bulan Ini', $validThisMonth)
                ->description('Absensi tervalidasi ' . $thisMonth->format('F Y'))
                ->color('success')
                ->icon('heroicon-o-check-badge'),
        ];
    }
}
