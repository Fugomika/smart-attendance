<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponse;
use App\Models\Office;
use App\Services\ActiveOfficeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class OfficeController extends Controller
{
    use ApiResponse;

    public function update(Request $request, string $id, ActiveOfficeService $activeOfficeService): JsonResponse
    {
        $request->validate([
            'officeName' => [
                'required',
                'string',
                'max:100',
                Rule::unique('offices', 'officeName')->ignore($id),
            ],
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radiusMeter' => 'required|integer|min:1',
        ]);

        $office = Office::whereKey($id)->where('isActive', true)->first();

        if (! $office) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $office = $activeOfficeService->update($office, [
            ...$request->only(['officeName', 'latitude', 'longitude', 'radiusMeter']),
            'isActive' => true,
        ]);

        return $this->success('Office updated successfully', [
            'id' => $office->id,
            'officeName' => $office->officeName,
            'latitude' => (float) $office->latitude,
            'longitude' => (float) $office->longitude,
            'radiusMeter' => (int) $office->radiusMeter,
            'isActive' => (bool) $office->isActive,
        ]);
    }
}
