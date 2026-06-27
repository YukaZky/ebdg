<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Coupon extends Model
{
    protected $fillable = [
        'id_user',
        'name',
        'code',
        'type',
        'value',
        'min_purchase',
        'max_discount',
        'usage_limit',
        'used_count',
        'description',
        'status',
        'starts_at',
        'expires_at',
    ];

    protected $casts = [
        'value' => 'float',
        'min_purchase' => 'float',
        'max_discount' => 'float',
        'usage_limit' => 'integer',
        'used_count' => 'integer',
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    public function takes()
    {
        return $this->hasMany(CouponTake::class, 'id_cuppon');
    }
}
