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
        Schema::create('attendances', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('UserId');
            $table->uuid('OfficeId')->nullable();
            $table->date('attendanceDate');
            $table->datetime('clockInTime')->nullable();
            $table->datetime('clockOutTime')->nullable();
            $table->decimal('clockInLat', 10, 7)->nullable();
            $table->decimal('clockInLng', 10, 7)->nullable();
            $table->boolean('isOutside')->default(false);
            $table->string('outsideReason')->nullable();
            $table->uuid('clockInPhotoId')->nullable();
            $table->enum('status', ['CHECKED_IN', 'PENDING', 'VALID', 'REJECTED', 'SICK', 'LEAVE', 'HOLIDAY']);
            $table->timestamps();
            $table->unique(['UserId', 'attendanceDate']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
