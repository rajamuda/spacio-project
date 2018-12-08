<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

/**
 * @property int $id
 * @property int $data_id
 * @property string $phenotype_name
 * @property string $created_at
 * @property string $updated_at
 * @property File $file
 */
class Phenotype extends Model
{
    /**
     * @var array
     */
    protected $fillable = ['data_id', 'phenotype_name', 'created_at', 'updated_at'];

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function file()
    {
        return $this->belongsTo('App\File', 'data_id');
    }
}
