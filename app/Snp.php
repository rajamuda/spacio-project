<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

/**
 * @property int $id
 * @property int $data_id
 * @property string $rs_id
 * @property string $genotype
 * @property string $position
 * @property string $chromosome
 * @property string $created_at
 * @property string $updated_at
 * @property File $file
 */
class Snp extends Model
{
    /**
     * @var array
     */
    protected $fillable = ['data_id', 'rs_id', 'genotype', 'position', 'chromosome', 'created_at', 'updated_at'];

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function file()
    {
        return $this->belongsTo('App\File', 'data_id');
    }
}
