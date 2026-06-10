<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductVariation extends Model
{
    protected $fillable = ['product_id', 'name', 'image', 'description'];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}