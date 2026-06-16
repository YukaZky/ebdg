<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CartItem extends Model
{
    protected $fillable = [
        'user_id',
        'product_id',
        'variation_id',
        'variation_name',
        'quantity',
        'price',
        'selected_image',
        'weight',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'quantity' => 'integer',
        'weight' => 'integer',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function variation()
    {
        return $this->belongsTo(ProductVariation::class, 'variation_id');
    }

    public function getSubtotalAttribute()
    {
        return $this->price * $this->quantity;
    }
}
