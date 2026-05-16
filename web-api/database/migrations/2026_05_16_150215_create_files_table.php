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
        Schema::create('files', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('objectKey')->unique();
            $table->string('originalName');
            $table->string('bucket', 50);
            $table->string('contentType', 127);
            $table->string('context', 50)->nullable();
            $table->boolean('isPublic')->default(false);
            $table->enum('status', ['PENDING', 'CONFIRMED', 'DELETED'])->default('PENDING');
            $table->uuid('UserId');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('files');
    }
};
