<?php

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ProcessStatusSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        //
    	DB::table('process_status')->insert([
    		[
    			'name' => 'Uploaded',
    			'description' => 'Files required have been succesfully uploaded to server and can be used for association analysis',
                'created_at' => date('Y-m-d H:i:s')
    		],
    		[
    			'name' => 'Analysing',
    			'description' => 'Running SNP-phenotype association analysis process',
                'created_at' => date('Y-m-d H:i:s')
    		],
    		[
    			'name' => 'Finished',
    			'description' => 'Association process has been completed',
                'created_at' => date('Y-m-d H:i:s')
    		],
    		[
    			'name' => 'Failed',
    			'description' => 'An error occured or there is something wrong in the process',
                'created_at' => date('Y-m-d H:i:s')
    		]
    	]);
    }
}
