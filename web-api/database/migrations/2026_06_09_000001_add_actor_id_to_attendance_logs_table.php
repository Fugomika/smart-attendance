<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendance_logs', function (Blueprint $table) {
            $table->uuid('ActorId')->nullable()->after('AttendanceId');
            $table->foreign('ActorId')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::table('attendance_logs', function (Blueprint $table) {
            $table->dropForeign(['ActorId']);
            $table->dropColumn('ActorId');
        });
    }
};
