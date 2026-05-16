<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->foreign('PhotoId')->references('id')->on('files');
        });

        Schema::table('files', function (Blueprint $table) {
            $table->foreign('UserId')->references('id')->on('users');
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->foreign('UserId')->references('id')->on('users');
            $table->foreign('OfficeId')->references('id')->on('offices');
            $table->foreign('clockInPhotoId')->references('id')->on('files');
        });

        Schema::table('attendance_logs', function (Blueprint $table) {
            $table->foreign('AttendanceId')->references('id')->on('attendances');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendance_logs', function (Blueprint $table) {
            $table->dropForeign(['AttendanceId']);
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->dropForeign(['UserId']);
            $table->dropForeign(['OfficeId']);
            $table->dropForeign(['clockInPhotoId']);
        });

        Schema::table('files', function (Blueprint $table) {
            $table->dropForeign(['UserId']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['PhotoId']);
        });
    }
};
