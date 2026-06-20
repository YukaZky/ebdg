<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentMethod extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'payment_type',
        'bank_code',
        'icon_path',
        'is_active'
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    // Otomatis menambahkan field 'icon_url' di respon JSON
    protected $appends = ['icon_url'];

    public function getIconUrlAttribute()
    {
        // Menyasar folder public/assets/images/payment/ pada proyek Laravel Anda
        return asset('assets/images/payment/' . $this->icon_path);
    }
}