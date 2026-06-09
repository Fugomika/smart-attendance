<?php

namespace App\Services;

use App\Models\File;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Throwable;

class RegistrationService
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function register(array $attributes, ?UploadedFile $avatar = null): User
    {
        $avatarPath = null;

        try {
            return DB::transaction(function () use ($attributes, $avatar, &$avatarPath): User {
                $user = User::create([
                    'name' => $attributes['name'],
                    'email' => $attributes['email'],
                    'password' => Hash::make($attributes['password']),
                    'jabatan' => $attributes['jabatan'] ?? null,
                    'role' => 'EMPLOYEE',
                    'status' => 'ACTIVE',
                ]);

                if (! $avatar) {
                    return $user;
                }

                $avatarPath = $avatar->store('uploads/profile_photo', 'public');

                if (! is_string($avatarPath)) {
                    throw new RuntimeException('Avatar storage failed.');
                }

                $file = File::create([
                    'objectKey' => $avatarPath,
                    'originalName' => $avatar->getClientOriginalName(),
                    'bucket' => 'public',
                    'contentType' => $avatar->getMimeType(),
                    'context' => 'profile_photo',
                    'isPublic' => true,
                    'status' => 'CONFIRMED',
                    'UserId' => $user->id,
                ]);

                $this->afterAvatarStored($user, $file);

                $user->update(['PhotoId' => $file->id]);
                $user->setRelation('photo', $file);

                return $user;
            });
        } catch (Throwable $exception) {
            if ($avatarPath) {
                Storage::disk('public')->delete($avatarPath);
            }

            throw $exception;
        }
    }

    protected function afterAvatarStored(User $user, File $file): void
    {
        //
    }
}
