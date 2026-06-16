<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'slug',
        'short_description',
        'description',
        'regular_price',
        'sale_price',
        'weight_gram',
        'SKU',
        'stock_status',
        'featured',
        'quantity',
        'weight',
        'image',
        'images',
        'category_id',
        'brand_id'
    ];

    protected $appends = ['active_price', 'discount_percentage', 'rating_average', 'rating_count'];

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function brand()
    {
        return $this->belongsTo(Brand::class, 'brand_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function store()
    {
        return $this->hasOne(StoreProfile::class, 'user_id', 'user_id');
    }

    public function variations()
    {
        return $this->hasMany(ProductVariation::class);
    }

    public function reviews()
    {
        return $this->hasMany(ProductReview::class);
    }

    public function getActivePriceAttribute()
    {
        return $this->sale_price && $this->sale_price < $this->regular_price
            ? $this->sale_price
            : $this->regular_price;
    }

    public function getDiscountPercentageAttribute()
    {
        if ($this->regular_price && $this->sale_price && $this->regular_price > $this->sale_price) {
            return round((($this->regular_price - $this->sale_price) / $this->regular_price) * 100);
        }

        return 0;
    }

    public function getRatingAverageAttribute()
    {
        return round((float) $this->reviews()->avg('rating'), 2);
    }

    public function getRatingCountAttribute()
    {
        return $this->reviews()->count();
    }
}
