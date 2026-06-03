<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Brand extends Model
{
    use HasFactory;

    // Tambahkan 'category_id'
    protected $fillable = [
        'name',
        'slug',
        'image',
        'category_id',
    ];

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    // Tambahkan fungsi ini untuk relasi ke Category
    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}