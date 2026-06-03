<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    // Tambahkan fungsi ini untuk relasi ke Brand
    public function brands()
    {
        return $this->hasMany(Brand::class);
    }
}