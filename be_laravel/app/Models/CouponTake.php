<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CouponTake extends Model
{
    protected $table = 'cuppon_takes';

    protected $fillable = [
        'id_cuppon',
        'id_user',
        'status',
    ];

    public function coupon()
    {
        return $this->belongsTo(Coupon::class, 'id_cuppon');
    }
}
