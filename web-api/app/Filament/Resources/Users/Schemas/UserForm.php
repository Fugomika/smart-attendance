<?php

namespace App\Filament\Resources\Users\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Hash;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nama Lengkap')
                    ->required()
                    ->maxLength(100),

                TextInput::make('email')
                    ->label('Email')
                    ->email()
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(100),

                TextInput::make('password')
                    ->label('Password')
                    ->password()
                    ->revealable()
                    ->required(fn (string $operation): bool => $operation === 'create')
                    ->dehydrateStateUsing(fn ($state) => filled($state) ? Hash::make($state) : null)
                    ->dehydrated(fn ($state) => filled($state))
                    ->placeholder(fn (string $operation): string => $operation === 'edit' ? 'Kosongkan jika tidak ingin mengubah' : ''),

                Select::make('role')
                    ->label('Role')
                    ->options([
                        'ADMIN' => 'Admin',
                        'EMPLOYEE' => 'Employee',
                    ])
                    ->required()
                    ->default('EMPLOYEE'),

                TextInput::make('jabatan')
                    ->label('Jabatan')
                    ->maxLength(100),

                Select::make('status')
                    ->label('Status')
                    ->options([
                        'ACTIVE' => 'Aktif',
                        'INACTIVE' => 'Nonaktif',
                    ])
                    ->required()
                    ->default('ACTIVE'),
            ]);
    }
}
