<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    // WAJIB ADA: Mendaftarkan kolom apa saja yang boleh diisi datanya
    protected $fillable = [
        'user_id',
        'name',
        'slug',
        'image',
    ];

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function brands()
    {
        return $this->hasMany(Brand::class);
    }

    // TAMBAHAN: Relasi ke tabel users (untuk mengetahui siapa admin pembuatnya)
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}