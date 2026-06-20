<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'subtotal', 'discount', 'tax', 'total', 
        'mode_pengiriman', 'jenis_pengiriman', 'ongkir', 
        'name', 'phone', 'locality', 'address', 'city', 
        'state', 'country', 'landmark', 'zip', 'type', 
        'status', 'is_shipping_different', 'delivered_date', 'canceled_date'
    ];

    public function transaction()
    {
        return $this->hasOne(Transaction::class);
    }

    // --- TAMBAHKAN RELASI INI ---
    /**
     * Relasi ke tabel order_items
     */
    public function items()
    {
        // Hubungkan ke model OrderItem menggunakan foreign key order_id
        return $this->hasMany(OrderItem::class, 'order_id', 'id');
    }

    /**
     * Relasi ke tabel users
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}