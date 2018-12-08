<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\File;
use Hashids\Hashids
use Illuminate\Support\Facades\DB;

class SubmissionController extends Controller
{
    private static function fileNameFilter ($file_name)
    {
    	// to lower all chars and replace space with underscore
		$file_name = str_replace(' ', '_', strtolower($file_name));

    	// only accept alphanumeric characters
    	$file_name = preg_replace('/[^a-zA-Z0-9_.-]/', '', $file_name);

    	return $file_name;
    }

    public function upload (Request $request)
    {
    	/* 	SECURITY CONCERN:
    		Severity: Mid to High

    		Problem: file's mime validation currently allowing type csv alongside with txt, but it can allowing user for uploading malicious text file contain 'evil' script.

    		Solution: uploaded files must be validated internally
		*/
    	$this->validate($request, [
    		'project_name' => 'required',
    		'organism' => 'required',
    		'snps' => 'required|mimes:csv,txt',
    		'phenotype' => 'required|mimes:csv,txt'
    	]);

    	$snps = $this->fileNameFilter($request->file('snps')->getClientOriginalName());
    	$phenotype = $this->fileNameFilter($request->file('phenotype')->getClientOriginalName());

    	echo $snps."<br/>".$phenotype;


    	DB::beginTransaction();
    	try
    	{
    		$file_id = File::insert([
		    			'user_id' => $request->user()->id,
		    			'status_id' => 1,
		    			'project_name' => $request->project_name,
		    			'organism' => $request->organism,
		    			'snps_data' => $snps,
		    			'phenotype_data' => $phenotype,
		    			'configuration' => "default",
		    			'created_at' => date('Y-m-d H:i:s')
		    		]);

    		$hashid = new Hashids('f1l3-s3cr3t', '10', 'abcdefghijklmnopqrstuvwxyz0123456789');

    		File::update([
    			'hashid' => $hashid->encode($file_id)
    		])->where('id', $file_id);

    		DB::commit();
    	}
    	catch (\Exception $e)
    	{
    		DB::rollback();
    	}
    }
}
