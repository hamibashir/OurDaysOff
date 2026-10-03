<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plan_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('plan_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('rsvp_status')->default('pending'); // attending, tentative, declined, pending
            $table->timestamp('responded_at')->nullable();
            $table->timestamps();

            $table->unique(['plan_id', 'user_id']);
            $table->index(['plan_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plan_members');
    }
};
