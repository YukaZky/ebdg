<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductVariation extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'name',
        'description',
        'regular_price',
        'sale_price',
        'weight',
        'quantity',
        'image',
    ];

    protected $appends = ['image_url'];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function getImageUrlAttribute()
    {
        $image = trim((string) $this->image);

        if ($image === '' || strtolower($image) === 'null') {
            return null;
        }

        if (str_starts_with($image, 'http://') || str_starts_with($image, 'https://')) {
            return $image;
        }

        $cleanImage = basename(ltrim($image, '/'));

        return url('/api/product-image/' . $cleanImage);
    }
}
