<?php

namespace App\Http\Controllers;

use App\Http\Traits\ApiResponse;
use App\Models\File;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    use ApiResponse;

    public function update(Request $request, string $id): JsonResponse
    {
        if ($id !== $request->user()->id) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        $request->validate([
            'name' => 'sometimes|string|min:1|max:100',
            'jabatan' => 'nullable|string|max:100',
            'photoId' => 'nullable|uuid',
        ]);

        $user = $request->user()->load('photo');

        if ($request->has('photoId')) {
            $newPhotoId = $request->photoId;
            $oldPhoto = $user->photo;

            if ($newPhotoId !== null) {
                $newPhoto = File::find($newPhotoId);
                if (!$newPhoto) {
                    return response()->json(['message' => 'Not found'], 404);
                }
                $newPhoto->update(['status' => 'CONFIRMED']);
                $user->setAttribute('PhotoId', $newPhotoId);
                $user->setRelation('photo', $newPhoto);
            } else {
                $user->setAttribute('PhotoId', null);
                $user->setRelation('photo', null);
            }

            if ($oldPhoto && $oldPhoto->id !== $newPhotoId) {
                $oldPhoto->update(['status' => 'DELETED']);
            }
        }

        if ($request->has('name')) {
            $user->name = $request->name;
        }
        if ($request->has('jabatan')) {
            $user->jabatan = $request->jabatan;
        }

        $user->save();

        return $this->success('Profile updated successfully', $this->formatUser($user));
    }

    public function updatePassword(Request $request, string $id): JsonResponse
    {
        if ($id !== $request->user()->id) {
            return response()->json(['message' => 'Access denied'], 403);
        }

        $request->validate([
            'oldPassword' => 'required|string',
            'newPassword' => 'required|string|min:6',
        ]);

        $user = $request->user();

        if (!Hash::check($request->oldPassword, $user->password)) {
            return response()->json(['message' => 'Old password is incorrect'], 400);
        }

        if ($request->newPassword === $request->oldPassword) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => [['path' => 'newPassword', 'message' => 'New password must differ from old password']],
            ], 422);
        }

        $user->update(['password' => Hash::make($request->newPassword)]);

        return $this->success('Password updated successfully', null);
    }
}
