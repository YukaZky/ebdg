<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'order_id',
        'manual_payment_account_id',
        'mode',
        'status',
        'payment_token',
        'payment_url',
        'payment_details',
        'manual_payment_account_snapshot',
        'payment_expires_at',
        'payment_approved_at',
        'payment_approved_by',
    ];

    protected $casts = [
        'manual_payment_account_snapshot' => 'array',
        'payment_expires_at' => 'datetime',
        'payment_approved_at' => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function manualPaymentAccount()
    {
        return $this->belongsTo(ManualPaymentAccount::class);
    }

    public function confirmations()
    {
        return $this->hasMany(ManualPaymentConfirmation::class);
    }

    public function latestConfirmation()
    {
        return $this->hasOne(ManualPaymentConfirmation::class)->latestOfMany('submitted_at');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'payment_approved_by');
    }
}
