<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'subtotal', 'discount', 'tax', 'total',
        'mode_pengiriman', 'jenis_pengiriman', 'ongkir', 'shipping_breakdown',
        'name', 'phone', 'locality', 'address', 'city',
        'state', 'country', 'landmark', 'zip', 'type',
        'status', 'is_shipping_different', 'delivered_date', 'completed_at', 'canceled_date'
    ];

    protected $casts = [
        'shipping_breakdown' => 'array',
        'completed_at' => 'datetime',
    ];

    public function transaction()
    {
        return $this->hasOne(Transaction::class);
    }

    /**
     * Relasi ke tabel order_items.
     */
    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id', 'id');
    }

    /**
     * Alias relasi untuk kompatibilitas kode lama di dashboard admin.
     */
    public function orderItems()
    {
        return $this->items();
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
