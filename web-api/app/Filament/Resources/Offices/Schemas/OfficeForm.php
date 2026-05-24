<?php

namespace App\Filament\Resources\Offices\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class OfficeForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('officeName')
                    ->label('Nama Kantor')
                    ->required()
                    ->maxLength(100),

                TextInput::make('latitude')
                    ->label('Latitude')
                    ->required()
                    ->numeric()
                    ->step(0.0000001)
                    ->helperText('Contoh: -6.2088'),

                TextInput::make('longitude')
                    ->label('Longitude')
                    ->required()
                    ->numeric()
                    ->step(0.0000001)
                    ->helperText('Contoh: 106.8456'),

                TextInput::make('radiusMeter')
                    ->label('Radius (meter)')
                    ->required()
                    ->numeric()
                    ->minValue(1)
                    ->suffix('m'),

                Toggle::make('isActive')
                    ->label('Aktif')
                    ->required()
                    ->default(true),
            ]);
    }
}
