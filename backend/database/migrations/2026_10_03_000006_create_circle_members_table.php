<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('circle_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('circle_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role')->default('member'); // owner, admin, member
            $table->string('member_type')->default('working'); // working, viewer
            $table->string('visibility')->default('free_busy'); // free_busy, shifts, details
            $table->string('status')->default('active'); // pending, active, removed
            $table->timestamp('joined_at')->nullable();
            $table->timestamps();

            $table->unique(['circle_id', 'user_id']);
            $table->index(['circle_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('circle_members');
    }
};
