<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_devices', function (Blueprint $table) {
            $table->string('pairing_code', 6)->nullable()->after('device_identifier');
            $table->timestamp('pairing_code_expires_at')->nullable()->after('pairing_code');
        });
    }

    public function down(): void
    {
        Schema::table('user_devices', function (Blueprint $table) {
            $table->dropColumn(['pairing_code', 'pairing_code_expires_at']);
        });
    }
};
