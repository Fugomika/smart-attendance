<?php

namespace App\Filament\Resources\AttendanceLogs\Tables;

use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class AttendanceLogsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('attendance.user.name')
                    ->label('Karyawan')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('attendance.attendanceDate')
                    ->label('Tanggal Absen')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('statusBefore')
                    ->label('Status Sebelum')
                    ->badge()
                    ->placeholder('-')
                    ->color(fn (?string $state): string => match ($state) {
                        'VALID' => 'success',
                        'CHECKED_IN' => 'info',
                        'PENDING' => 'warning',
                        'REJECTED' => 'danger',
                        default => 'gray',
                    }),

                TextColumn::make('statusAfter')
                    ->label('Status Sesudah')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'VALID' => 'success',
                        'CHECKED_IN' => 'info',
                        'PENDING' => 'warning',
                        'REJECTED' => 'danger',
                        default => 'gray',
                    }),

                TextColumn::make('note')
                    ->label('Catatan')
                    ->placeholder('-')
                    ->wrap()
                    ->toggleable(),

                TextColumn::make('created_at')
                    ->label('Waktu Perubahan')
                    ->dateTime('d M Y, H:i')
                    ->sortable(),
            ])
            ->filters([])
            ->defaultSort('created_at', 'desc');
    }
}
