<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponse;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'query' => 'sometimes|string',
            'status' => 'sometimes|in:ACTIVE,INACTIVE',
            'page' => 'sometimes|integer|min:1',
            'pageSize' => 'sometimes|integer|min:1|max:100',
            'sortOrder' => 'sometimes|in:ASC,DESC',
        ]);

        $query = User::with('photo');

        if ($request->filled('query')) {
            $search = $request->string('query')->toString();
            $query->where(fn ($builder) => $builder
                ->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%"));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $query->orderBy('name', $request->get('sortOrder', 'ASC'));

        $paginator = $query->paginate(
            (int) $request->get('pageSize', 20),
            ['*'],
            'page',
            $request->get('page', 1),
        );

        return $this->paginate('Data retrieved successfully', $paginator, fn (User $user) => $this->formatUser($user, true));
    }

    public function show(string $id): JsonResponse
    {
        $user = User::with('photo')->find($id);

        if (! $user) {
            return response()->json(['message' => 'Not found'], 404);
        }

        return $this->success('Data retrieved successfully', $this->formatUser($user, true));
    }
}
