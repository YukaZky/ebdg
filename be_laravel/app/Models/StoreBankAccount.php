<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StoreBankAccount extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'slot',
        'provider',
        'account_number',
        'account_name',
    ];

    protected $casts = [
        'slot' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
