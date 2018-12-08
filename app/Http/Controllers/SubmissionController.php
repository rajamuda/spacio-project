<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\File;
use Hashids\Hashids;
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

    private static function hashId ($id, $type)
    {
		$hashid = new Hashids(
					config('app.hashid.secret'), 
					config('app.hashid.padding'), 
					config('app.hashid.characters')
				);

		if($type === "encode")
			return $hashid->encode($id);
		else if($type === "decode")
			return $hashid->decode($id);
    }

    /*
    |--------------------------------------------------------------------------
	| Router specific function
    |--------------------------------------------------------------------------
	| upload: handling /submission/add form
	| getAll: get all submission data
	| runAnalysis: run the association analysis process in the background
	|
	|
    */
    public function upload (Request $request)
    {
    	/* 	SECURITY CONCERN:
    		Severity: Mid to High

    		Problem: file's mime validation currently allowing csv alongside with txt, but it can allowing user to uploading malicious text file contain 'evil' script.

    		Solution: uploaded files must be validated internally. Check wether each files trully csv-formatted.
		*/
    	$this->validate($request, [
    		'project_name' => 'required',
    		'organism' => 'required',
    		'snps' => 'required|mimes:csv,txt',
    		'phenotype' => 'required|mimes:csv,txt'
    	]);

    	$snps = $request->file('snps');
    	$phenotype = $request->file('phenotype');

    	$snps_file = "snps_".$this->fileNameFilter($snps->getClientOriginalName());
    	$phenotype_file = "pheno_".$this->fileNameFilter($phenotype->getClientOriginalName());


    	DB::beginTransaction();
    	try
    	{
			// Insert data
			$file = new File();
			$file->user_id = $request->user()->id;
			$file->status_id = 1;
			$file->project_name = $request->project_name;
			$file->organism = $request->organism;
			$file->snps_data = $snps_file;
			$file->phenotype_data = $phenotype_file;
			$file->configuration = "default";
			$file->created_at = date('Y-m-d H:i:s');
			$file->save();

			// Generate HashID and create new directory path
    		$hashid = $this->hashId($file->id, "encode");
    		$path = base_path('resources/data/'.$hashid);
    		if (mkdir($path))
    		{
	    		$snps->move($path, $snps_file);
	    		$phenotype->move($path, $phenotype_file);
	    	}
	    	else 
	    	{
	    		throw new \Exception('Directory creation failed!');
	    	}

			// Update hashid field in file's table
    		File::where('id', $file->id)->update([
    			'hashid' => $hashid
    		]);

    		DB::commit();
    		return ['status' => true, 'message' => 'Success uploading data'];
    	}
    	catch (\Exception $e)
    	{
    		DB::rollback();
    		return ['status' => false, 'message' => $e->getMessage()];
    	}
    }
}
