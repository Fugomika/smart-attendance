<?php

namespace App\Filament\Resources\Offices\Pages;

use App\Filament\Resources\Offices\OfficeResource;
use App\Services\ActiveOfficeService;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Database\Eloquent\Model;

class CreateOffice extends CreateRecord
{
    protected static string $resource = OfficeResource::class;

    protected function handleRecordCreation(array $data): Model
    {
        return app(ActiveOfficeService::class)->create($data);
    }
}
