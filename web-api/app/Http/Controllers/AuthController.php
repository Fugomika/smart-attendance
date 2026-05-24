<?php

namespace App\Http\Controllers;

use App\Http\Traits\ApiResponse;
use App\Models\File;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    use ApiResponse;

    public function mobileLogin(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::with('photo')->where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        if ($user->status === 'INACTIVE') {
            return response()->json(['message' => 'Access denied'], 403);
        }

        $token = $user->createToken('mobile-app', ['*'], now()->addSeconds(604800));

        return $this->success('Login successful', [
            'accessToken' => $token->plainTextToken,
            'expiresIn' => 604800,
            'user' => $this->formatUser($user),
        ]);
    }

    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email',
            'password' => 'required|string|min:6',
            'jabatan' => 'nullable|string|max:100',
            'photoId' => 'nullable|uuid',
        ]);

        if (User::where('email', $request->email)->exists()) {
            return response()->json(['message' => 'Email already registered'], 409);
        }

        $photoFile = null;
        if ($request->photoId) {
            $photoFile = File::find($request->photoId);
            if (!$photoFile) {
                return response()->json(['message' => 'Not found'], 404);
            }
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'jabatan' => $request->jabatan,
            'role' => 'EMPLOYEE',
            'status' => 'ACTIVE',
            'PhotoId' => $photoFile?->id,
        ]);

        if ($photoFile) {
            $photoFile->update(['status' => 'CONFIRMED']);
            $user->setRelation('photo', $photoFile);
        }

        return $this->success('Registration successful', $this->formatUser($user), 201);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => 'required|email']);

        return $this->success('Jika email terdaftar, instruksi reset password akan dikirim', null);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('photo');
        $data = $this->formatUser($user);
        $data['createdAt'] = $user->created_at?->setTimezone('Asia/Jakarta')->format('Y-m-d\TH:i:sP');

        return $this->success('Data retrieved successfully', $data);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->success('Logout successful', null);
    }
}
