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
	
	private static function parseCsv ($csv)
	{

	}

    /*
    |--------------------------------------------------------------------------
	| Router specific function
    |--------------------------------------------------------------------------
	| GET getOne: get one submission
	| GET getAll: get all submission data
	| POST upload: handling /submission/add form
	| POST runAnalysis: run the association analysis process in the background
	| POST stopAnalysis: stop association analysis process (TO DO)
	|
	*/
	public function getOne (Request $request)
	{
		$user_id = $request->user()->id;
		$id = $this->hashId($request->hash_id, "decode");
		
		if($id){
			$file = File::with('processStatus')->where([
						['user_id', '=', $user_id],
						['id', '=', $id[0]]
					])->first();
			
			if($file){
				// Read log.txt, error.txt, result.csv, and metrics.json
				$file_dir = base_path('resources/data/'.$file->hashid);

				// if file is not exist, simply null or false it (that is why I used '@')
				$log = @file_get_contents($file_dir."/log.txt");
				$error = @file_get_contents($file_dir."/error.txt");
				$metrics = json_decode(@file_get_contents($file_dir."/metrics.json"));

				return ['file' => $file, 'log' => $log, 'error' => $error, 'metrics' => $metrics];
			}
		}

		return response(['status' => false, 'message' => 'File is not exist'], 404);	
	}

	public function getAll (Request $request)
	{
		$user_id = $request->user()->id;

		$uploaded = File::with('processStatus')->where([
						['user_id', '=', $user_id], 
						['status_id', '=', 1]])
					->get();
		
		$running = File::with('processStatus')->where([
						['user_id', '=', $user_id], 
						['status_id', '=', 2]])
					->get();

		$finished = File::with('processStatus')->where([
						['user_id', '=', $user_id]])
						->whereIn('status_id', [3, 4])
					->get();

		return [
			'file' => [
					'uploaded' => $uploaded,
					'running' => $running,
					'finished' => $finished
				]
			];
		
	}

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
    	try {
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
    		if (mkdir($path)) {
	    		$snps->move($path, $snps_file);
	    		$phenotype->move($path, $phenotype_file);
	    	} else {
	    		throw new \Exception('Directory creation failed!');
	    	}

			// Update hashid field in file's table
    		File::where('id', $file->id)->update([
    			'hashid' => $hashid
    		]);

    		DB::commit();
    		return response(['status' => true, 'message' => 'Success uploading data', 'hashid' => $hashid], 200);
    	} catch (\Exception $e) {
    		DB::rollback();
    		return response(['status' => false, 'message' => $e->getMessage()], 500);
    	}
	}

	public function runAnalysis (Request $request) 
	{
		$file_id = $request->file_id;

		$id = $this->hashId($file_id, "decode");
		if (!$id) {
			return response(['status' => false, 'message' => 'File is not exist'], 404);
		} 
		$file = File::where('id', $id[0])->first();
		if($file->status_id > 1) {
			return response(['status' => false, 'message' => 'Process already running or finished'], 422);
		}

		$os = php_uname('s');
		$script_path = base_path('resources/codes/dani.R');
		$output_path = base_path('resources/data/'.$file_id);
		$descriptorspec = [  
			0 => ["pipe", "r"],  
			1 => ["pipe", "w"],  
		];  

		//Preparing the command
		$Rscript = config('app.rscript');
		$cmd = "$Rscript $script_path -s $file->snps_data -p $file->phenotype_data -a $file->hashid > $output_path/log.txt 2> $output_path/error.txt";
			
		if ($os === "Windows NT") {
			if(is_resource($prog = proc_open("start /B ". $cmd, $descriptorspec, $pipes))) {
				// Get Parent process Id  
				$ppid = proc_get_status($prog);  
				$pid = $ppid['pid']; 
							
				// Get PID
				$output = array_filter(explode(" ", shell_exec("wmic process get parentprocessid,processid | find \"$pid\"")));  
				array_pop($output);    
				$pid = end($output);
			} else {
				return response(['status' => false, 'message' => 'Failed to execute'], 500);
			}
		} else if ($os === "Linux") {
			// $cmd = "$Rscript $script_path -s $file->snps_data -p $file->phenotype_data -a $file->hashid > $output_path/log.txt 2> $output_path/error.txt &";
			if(is_resource($prog = proc_open("nohup ". $cmd, $descriptorspec, $pipes))) {
				//Get Parent process Id   
				$ppid = proc_get_status($prog);  
				$pid = $ppid['pid'];  
				
				//Get PID 
				$pid = $pid+1;  
			} else {
				return response(['status' => false, 'message' => 'Failed to execute'], 500);
			}
		} else {
			return response(['status' => false, 'message' => 'Unsupported OS'], 422);
		}

		// Update File table: 
		// -- change status_id into 2 (performing analysis)
		// -- insert PID of current process
		$file->pid = $pid;
		$file->status_id = 2;
		$file->save();
	}
}
