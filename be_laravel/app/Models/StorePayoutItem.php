<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StorePayoutItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'payout_id',
        'seller_id',
        'order_id',
        'income_date',
        'amount',
    ];

    protected $casts = [
        'income_date' => 'date',
        'amount' => 'float',
    ];

    public function payout()
    {
        return $this->belongsTo(StorePayout::class, 'payout_id');
    }

    public function seller()
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
