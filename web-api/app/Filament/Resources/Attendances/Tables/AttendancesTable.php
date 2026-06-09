<?php

namespace App\Filament\Resources\Attendances\Tables;

use Filament\Actions\EditAction;
use Filament\Forms\Components\DatePicker;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class AttendancesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('user.name')
                    ->label('Karyawan')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('office.officeName')
                    ->label('Kantor')
                    ->searchable()
                    ->placeholder('-'),

                TextColumn::make('attendanceDate')
                    ->label('Tanggal')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('clockInTime')
                    ->label('Clock In')
                    ->dateTime('H:i')
                    ->placeholder('-'),

                TextColumn::make('clockOutTime')
                    ->label('Clock Out')
                    ->dateTime('H:i')
                    ->placeholder('-'),

                IconColumn::make('isOutside')
                    ->label('Luar Area')
                    ->boolean()
                    ->toggleable(),

                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'VALID' => 'success',
                        'CHECKED_IN' => 'info',
                        'PENDING' => 'warning',
                        'REJECTED' => 'danger',
                        'SICK' => 'gray',
                        'LEAVE' => 'gray',
                        'HOLIDAY' => 'gray',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'CHECKED_IN' => 'Checked In',
                        'PENDING' => 'Pending',
                        'VALID' => 'Valid',
                        'REJECTED' => 'Ditolak',
                        'SICK' => 'Sakit',
                        'LEAVE' => 'Cuti',
                        'HOLIDAY' => 'Hari Libur',
                        default => $state,
                    }),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d M Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Status')
                    ->options([
                        'CHECKED_IN' => 'Checked In',
                        'PENDING' => 'Pending',
                        'VALID' => 'Valid',
                        'REJECTED' => 'Ditolak',
                        'SICK' => 'Sakit',
                        'LEAVE' => 'Cuti',
                        'HOLIDAY' => 'Hari Libur',
                    ]),

                Filter::make('attendanceDate')
                    ->form([
                        DatePicker::make('from')->label('Dari Tanggal')->native(false),
                        DatePicker::make('until')->label('Sampai Tanggal')->native(false),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['from'], fn ($q) => $q->whereDate('attendanceDate', '>=', $data['from']))
                            ->when($data['until'], fn ($q) => $q->whereDate('attendanceDate', '<=', $data['until']));
                    }),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([])
            ->defaultSort('attendanceDate', 'desc');
    }
}
