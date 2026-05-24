<?php

namespace App\Filament\Resources\AttendanceLogs;

use App\Filament\Resources\AttendanceLogs\Pages\ListAttendanceLogs;
use App\Filament\Resources\AttendanceLogs\Schemas\AttendanceLogForm;
use App\Filament\Resources\AttendanceLogs\Tables\AttendanceLogsTable;
use App\Models\AttendanceLog;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class AttendanceLogResource extends Resource
{
    protected static ?string $model = AttendanceLog::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClock;

    protected static ?string $navigationLabel = 'Log Absensi';

    protected static ?string $modelLabel = 'Log Absensi';

    protected static ?string $pluralModelLabel = 'Log Absensi';


    public static function form(Schema $schema): Schema
    {
        return AttendanceLogForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return AttendanceLogsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAttendanceLogs::route('/'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }
}
