<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SellerWithdrawal extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'amount',
        'bank_name',
        'bank_account_number',
        'bank_account_name',
        'status',
        'note',
        'paid_at',
    ];

    protected $casts = [
        'amount' => 'float',
        'paid_at' => 'datetime',
    ];

    public function store()
    {
        return $this->belongsTo(StoreProfile::class, 'store_id');
    }

    public function balances()
    {
        return $this->hasMany(SellerBalance::class, 'seller_withdrawal_id');
    }
}
