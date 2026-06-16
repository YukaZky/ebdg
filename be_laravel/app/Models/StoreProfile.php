<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StoreProfile extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'slug',
        'logo',
        'banner',
        'phone',
        'description',
        'address',
        'maps_url',
        'province_name',
        'city_name',
        'instagram',
        'tiktok',
        'facebook',
        'website',
        'status',
        'rating_average',
        'rating_count',
    ];

    protected $casts = [
        'rating_average' => 'float',
        'rating_count' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function products()
    {
        return $this->hasMany(Product::class, 'user_id', 'user_id');
    }

    public function reviews()
    {
        return $this->hasMany(ProductReview::class, 'store_id');
    }
}
