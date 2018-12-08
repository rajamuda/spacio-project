<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

/**
 * @property int $id
 * @property int $user_id
 * @property int $status_id
 * @property string $hashid
 * @property string $project_name
 * @property string $organism
 * @property string $snps_data
 * @property string $phenotype_data
 * @property string $configuration
 * @property string $created_at
 * @property string $updated_at
 * @property ProcessStatus $processStatus
 * @property User $user
 * @property Phenotype[] $phenotypes
 * @property Snp[] $snps
 */
class File extends Model
{
    /**
     * @var array
     */
    protected $fillable = ['user_id', 'status_id', 'hashid', 'project_name', 'organism', 'snps_data', 'phenotype_data', 'configuration', 'created_at', 'updated_at'];

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function processStatus()
    {
        return $this->belongsTo('App\ProcessStatus', 'status_id');
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo
     */
    public function user()
    {
        return $this->belongsTo('App\User');
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function phenotypes()
    {
        return $this->hasMany('App\Phenotype', 'data_id');
    }

    /**
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function snps()
    {
        return $this->hasMany('App\Snp', 'data_id');
    }
}
