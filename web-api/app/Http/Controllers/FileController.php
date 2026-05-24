<?php

namespace App\Http\Controllers;

use App\Http\Traits\ApiResponse;
use App\Models\File;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FileController extends Controller
{
    use ApiResponse;

    public function upload(Request $request): JsonResponse
    {
        if (!$request->hasFile('file')) {
            return response()->json(['message' => 'Bad request'], 400);
        }

        $request->validate([
            'file' => 'required|file|mimes:jpeg,png|max:5120',
            'context' => 'required|in:profile_photo,attendance_selfie',
        ]);

        $context = $request->context;
        $uploaded = $request->file('file');
        $path = $uploaded->store("uploads/{$context}", 'public');

        $file = File::create([
            'objectKey' => $path,
            'originalName' => $uploaded->getClientOriginalName(),
            'bucket' => 'public',
            'contentType' => $uploaded->getMimeType(),
            'context' => $context,
            'isPublic' => true,
            'status' => 'PENDING',
            'UserId' => $request->user()->id,
        ]);

        return $this->success('File uploaded successfully', $this->formatFile($file), 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $file = File::where('id', $id)->where('status', '!=', 'DELETED')->first();

        if (!$file) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return $this->success('Data retrieved successfully', $this->formatFile($file));
    }
}
