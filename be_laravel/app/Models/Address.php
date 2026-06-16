<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Address extends Model
{
    protected $fillable = [
        'user_id',       
        'name',    
        'phone',
        'locality',      
        'address',    
        'city',
        'state',
        'country',
        'landmark',
        'zip',
        'type',
        'isdefault',     
        'province_id',
        'city_id',
        'district_id',
        'province_name',
        'city_name',
        'district_name',
        'postal_code',
        'label',
        'note',              
        'is_store_address',  
        'latitude',  
        'longitude',
    ];
    
    // Relasi ke User (Opsional tapi sangat disarankan)
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}