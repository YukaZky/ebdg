<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ManualPaymentAudit extends Model
{
    use HasFactory;

    protected $fillable = [
        'transaction_id',
        'order_id',
        'actor_id',
        'action',
        'from_status',
        'to_status',
        'reason',
        'metadata',
        'ip_address',
        'user_agent',
    ];

    protected $casts = [
        'metadata' => 'array',
    ];

    public function actor()
    {
        return $this->belongsTo(User::class, 'actor_id');
    }
}
