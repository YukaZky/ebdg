<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WhatsappSetting extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    // [PERBAIKAN] Tambahkan properti ini untuk mengizinkan mass assignment
    protected $fillable = ['key', 'value'];
}
