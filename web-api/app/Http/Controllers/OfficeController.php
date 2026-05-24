<?php

namespace App\Http\Controllers;

use App\Http\Traits\ApiResponse;
use App\Models\Office;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OfficeController extends Controller
{
    use ApiResponse;

    public function active(Request $request): JsonResponse
    {
        $office = Office::where('isActive', true)->first();

        if (!$office) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return $this->success('Data retrieved successfully', [
            'id' => $office->id,
            'officeName' => $office->officeName,
            'latitude' => (float) $office->latitude,
            'longitude' => (float) $office->longitude,
            'radiusMeter' => (int) $office->radiusMeter,
            'isActive' => (bool) $office->isActive,
        ]);
    }
}
