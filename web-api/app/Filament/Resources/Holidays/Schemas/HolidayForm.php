<?php

namespace App\Filament\Resources\Holidays\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class HolidayForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('holidayName')
                    ->label('Nama Hari Libur')
                    ->required()
                    ->maxLength(100),

                Select::make('holidayType')
                    ->label('Tipe')
                    ->options([
                        'NATIONAL' => 'Libur Nasional',
                        'COMPANY' => 'Libur Perusahaan',
                    ])
                    ->required(),

                DatePicker::make('startDate')
                    ->label('Tanggal Mulai')
                    ->required()
                    ->native(false),

                DatePicker::make('endDate')
                    ->label('Tanggal Selesai')
                    ->required()
                    ->native(false)
                    ->afterOrEqual('startDate'),
            ]);
    }
}
