<?php

namespace App\Filament\Resources\Attendances\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class AttendanceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Data Absensi')
                    ->description('Data dikirim dari aplikasi mobile')
                    ->schema([
                        Select::make('UserId')
                            ->label('Karyawan')
                            ->relationship('user', 'name')
                            ->required()
                            ->searchable()
                            ->preload()
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),

                        Select::make('OfficeId')
                            ->label('Kantor')
                            ->relationship('office', 'officeName')
                            ->searchable()
                            ->preload()
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),

                        DatePicker::make('attendanceDate')
                            ->label('Tanggal Absen')
                            ->required()
                            ->native(false)
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),

                        DateTimePicker::make('clockInTime')
                            ->label('Clock In')
                            ->native(false)
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),

                        DateTimePicker::make('clockOutTime')
                            ->label('Clock Out')
                            ->native(false)
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),

                        TextInput::make('clockInLat')
                            ->label('Latitude (Clock In)')
                            ->numeric()
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),

                        TextInput::make('clockInLng')
                            ->label('Longitude (Clock In)')
                            ->numeric()
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),

                        Toggle::make('isOutside')
                            ->label('Di Luar Area')
                            ->disabled(fn (string $operation): bool => $operation === 'edit'),
                    ])
                    ->columns(2),

                Section::make('Validasi HR')
                    ->schema([
                        Select::make('status')
                            ->label('Status Absensi')
                            ->options([
                                'CHECKED_IN' => 'Checked In',
                                'PENDING' => 'Pending',
                                'VALID' => 'Valid',
                                'REJECTED' => 'Ditolak',
                                'SICK' => 'Sakit',
                                'LEAVE' => 'Cuti',
                                'HOLIDAY' => 'Hari Libur',
                            ])
                            ->required()
                            ->disabled(),

                        Textarea::make('outsideReason')
                            ->label('Alasan Di Luar Area')
                            ->rows(3)
                            ->maxLength(255),
                    ]),
            ]);
    }
}
