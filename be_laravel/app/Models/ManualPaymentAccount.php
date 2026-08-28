<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ManualPaymentAccount extends Model
{
    use HasFactory;

    protected $fillable = [
        'account_type',
        'bank_name',
        'account_number',
        'account_name',
        'label',
        'instructions',
        'is_active',
        'is_primary',
        'created_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_primary' => 'boolean',
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
