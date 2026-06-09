<?php

namespace App\Services;

use App\Models\Office;
use DomainException;
use Illuminate\Support\Facades\DB;

class ActiveOfficeService
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(array $attributes): Office
    {
        return DB::transaction(function () use ($attributes): Office {
            $hasActiveOffice = Office::query()
                ->where('isActive', true)
                ->lockForUpdate()
                ->exists();

            $shouldActivate = ! $hasActiveOffice || (bool) ($attributes['isActive'] ?? false);

            if ($shouldActivate) {
                Office::query()->where('isActive', true)->update(['isActive' => false]);
            }

            return Office::create([
                ...$attributes,
                'isActive' => $shouldActivate,
            ]);
        });
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Office $office, array $attributes): Office
    {
        return DB::transaction(function () use ($office, $attributes): Office {
            $lockedOffice = Office::query()->lockForUpdate()->findOrFail($office->id);
            $willBeActive = (bool) ($attributes['isActive'] ?? $lockedOffice->isActive);

            if ($lockedOffice->isActive && ! $willBeActive) {
                throw new DomainException('Active office cannot be deactivated without a replacement.');
            }

            if ($willBeActive) {
                Office::query()
                    ->whereKeyNot($lockedOffice->id)
                    ->where('isActive', true)
                    ->update(['isActive' => false]);
            }

            $lockedOffice->update([
                ...$attributes,
                'isActive' => $willBeActive,
            ]);

            return $lockedOffice;
        });
    }

    public function delete(Office $office): void
    {
        DB::transaction(function () use ($office): void {
            $lockedOffice = Office::query()->lockForUpdate()->findOrFail($office->id);

            if ($lockedOffice->isActive) {
                throw new DomainException('Active office cannot be deleted without a replacement.');
            }

            $lockedOffice->delete();
        });
    }
}
