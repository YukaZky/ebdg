<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StorePayout extends Model
{
    use HasFactory;

    protected $fillable = [
        'seller_id',
        'processed_by',
        'income_date',
        'payout_date',
        'amount',
        'description',
        'proof_photo',
        'bank_provider',
        'account_number',
        'account_name',
        'status',
    ];

    protected $casts = [
        'income_date' => 'date',
        'payout_date' => 'date',
        'amount' => 'float',
    ];

    public function seller()
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function processor()
    {
        return $this->belongsTo(User::class, 'processed_by');
    }

    public function items()
    {
        return $this->hasMany(StorePayoutItem::class, 'payout_id');
    }
}
