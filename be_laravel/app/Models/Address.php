<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Address extends Model
{
    protected $fillable = [
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
    ];
}
