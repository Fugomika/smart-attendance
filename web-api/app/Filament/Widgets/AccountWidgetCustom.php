<?php

namespace App\Filament\Widgets;

use Filament\Facades\Filament;
use Filament\Widgets\Widget;

class AccountWidgetCustom extends Widget
{
    protected static ?int $sort = -3;

    protected int|string|array $columnSpan = 'full';

    protected static bool $isLazy = false;

    /**
     * @var view-string
     */
    protected string $view = 'filament-panels::widgets.account-widget';

    public static function canView(): bool
    {
        return Filament::auth()->check();
    }
}
