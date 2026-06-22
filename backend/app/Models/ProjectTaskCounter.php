<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProjectTaskCounter extends Model
{
    protected $primaryKey = 'project_id';

    protected $keyType = 'string';

    public $incrementing = false;

    public $timestamps = false;

    protected $guarded = [];
}
