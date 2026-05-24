<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

#[Signature('app:create-admin')]
#[Description('Buat akun admin untuk mengakses panel Filament')]
class CreateAdminUser extends Command
{
    public function handle(): int
    {
        $this->info('Buat Admin Filament');
        $this->line('─────────────────────────────');

        $name = $this->ask('Nama lengkap');

        $email = $this->ask('Email');
        if (User::where('email', $email)->exists()) {
            $this->error("Email '{$email}' sudah terdaftar.");
            return self::FAILURE;
        }

        $password = $this->secret('Password (min. 8 karakter)');
        $passwordConfirm = $this->secret('Konfirmasi password');

        $validator = Validator::make(
            ['name' => $name, 'email' => $email, 'password' => $password, 'password_confirm' => $passwordConfirm],
            [
                'name' => ['required', 'string', 'max:100'],
                'email' => ['required', 'email'],
                'password' => ['required', 'min:8'],
                'password_confirm' => ['required', 'same:password'],
            ]
        );

        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $error) {
                $this->error($error);
            }
            return self::FAILURE;
        }

        $jabatan = $this->ask('Jabatan (opsional, tekan Enter untuk skip)', null);

        $user = User::create([
            'name' => $name,
            'email' => $email,
            'password' => Hash::make($password),
            'role' => 'ADMIN',
            'jabatan' => $jabatan,
            'status' => 'ACTIVE',
        ]);

        $this->info('');
        $this->info("Admin berhasil dibuat!");
        $this->table(
            ['Field', 'Value'],
            [
                ['Nama', $user->name],
                ['Email', $user->email],
                ['Role', $user->role],
                ['Jabatan', $user->jabatan ?? '-'],
                ['Status', $user->status],
            ]
        );

        return self::SUCCESS;
    }
}
