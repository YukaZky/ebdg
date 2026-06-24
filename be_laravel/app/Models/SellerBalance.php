<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SellerBalance extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'order_id',
        'order_item_id',
        'seller_withdrawal_id',
        'gross_amount',
        'platform_fee',
        'amount',
        'type',
        'status',
        'available_at',
        'withdrawn_at',
    ];

    protected $casts = [
        'gross_amount' => 'float',
        'platform_fee' => 'float',
        'amount' => 'float',
        'available_at' => 'datetime',
        'withdrawn_at' => 'datetime',
    ];

    public function store()
    {
        return $this->belongsTo(StoreProfile::class, 'store_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function orderItem()
    {
        return $this->belongsTo(OrderItem::class);
    }

    public function withdrawal()
    {
        return $this->belongsTo(SellerWithdrawal::class, 'seller_withdrawal_id');
    }
}
