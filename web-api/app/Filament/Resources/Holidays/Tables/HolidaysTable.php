<?php

namespace App\Filament\Resources\Holidays\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class HolidaysTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('holidayName')
                    ->label('Nama Hari Libur')
                    ->searchable()
                    ->sortable(),

                TextColumn::make('holidayType')
                    ->label('Tipe')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'NATIONAL' => 'Libur Nasional',
                        'COMPANY' => 'Libur Perusahaan',
                        default => $state,
                    })
                    ->color(fn (string $state): string => match ($state) {
                        'NATIONAL' => 'warning',
                        'COMPANY' => 'info',
                        default => 'gray',
                    }),

                TextColumn::make('startDate')
                    ->label('Mulai')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('endDate')
                    ->label('Selesai')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d M Y')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('holidayType')
                    ->label('Tipe')
                    ->options([
                        'NATIONAL' => 'Libur Nasional',
                        'COMPANY' => 'Libur Perusahaan',
                    ]),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ])
            ->defaultSort('startDate', 'desc');
    }
}
