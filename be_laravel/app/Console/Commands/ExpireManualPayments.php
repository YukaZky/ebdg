<?php

namespace App\Console\Commands;

use App\Services\ManualPaymentService;
use Illuminate\Console\Command;

class ExpireManualPayments extends Command
{
    protected $signature = 'payments:expire-manual';

    protected $description = 'Membatalkan pembayaran manual yang melewati batas 24 jam dan belum mengirim bukti';

    public function handle(ManualPaymentService $payments): int
    {
        $count = $payments->expireDuePayments();
        $this->info("{$count} pembayaran manual kedaluwarsa diproses.");

        return self::SUCCESS;
    }
}
