<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class About extends Model
{
    use HasFactory;

    protected $fillable = [
        'logo_image', 
        'poster_image', 
        'our_story', 
        'our_vision', 
        'our_mission', 
        'the_company',
        'province_id',
        'city_id',
        'district_id',
        'id',
    ];
}