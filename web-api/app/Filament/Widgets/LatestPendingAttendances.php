<?php

namespace App\Filament\Widgets;

use App\Filament\Resources\Attendances\AttendanceResource;
use App\Models\Attendance;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

class LatestPendingAttendances extends TableWidget
{
    protected static ?string $heading = 'Absensi Menunggu Validasi';

    protected static ?int $sort = 2;

    protected int|string|array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                fn (): Builder => Attendance::query()
                    ->with(['user', 'office'])
                    ->where('status', 'PENDING')
                    ->latest('updated_at')
            )
            ->columns([
                TextColumn::make('user.name')
                    ->label('Karyawan')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('attendanceDate')
                    ->label('Tanggal')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('clockInTime')
                    ->label('Clock In')
                    ->dateTime('H:i')
                    ->placeholder('-'),

                TextColumn::make('office.officeName')
                    ->label('Kantor')
                    ->placeholder('-'),

                TextColumn::make('isOutside')
                    ->label('Luar Area')
                    ->formatStateUsing(fn (bool $state): string => $state ? 'Ya' : 'Tidak')
                    ->badge()
                    ->color(fn (bool $state): string => $state ? 'warning' : 'success'),

                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color('warning'),
            ])
            ->recordUrl(
                fn (Attendance $record): string => AttendanceResource::getUrl('edit', ['record' => $record])
            )
            ->emptyStateHeading('Tidak ada absensi pending')
            ->emptyStateDescription('Semua absensi sudah divalidasi.')
            ->emptyStateIcon('heroicon-o-check-circle')
            ->paginated(false);
    }
}
