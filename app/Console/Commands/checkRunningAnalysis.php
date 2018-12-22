<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\File;

class checkRunningAnalysis extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'analysis:check-running-process';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check currently running analysis process';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        while (true) {
            $runningProcess = File::where('status_id', '2')->get();

            foreach ($runningProcess as $process) {
                if (!$this->isProcessRunning($process->pid)) {
                    echo date('Y-m-d H:i:s')." $process->project_name ($process->hashid) with PID $process->pid already stopped\n";

                    if (!$this->isProcessHasError($process->hashid)) {
                        // update status_id into 3, PID into null
                        $this->updateProcess($process->id, 3);
                    } else {
                        // update status_id into 4, PID into null
                        $this->updateProcess($process->id, 4);
                    }
                }  
            }
            sleep(10);
        }
    }

    public function isProcessRunning ($pid) {
 		$os = php_uname('s');
        
        if ($os === "Windows NT") {
            $process = shell_exec(sprintf('tasklist /FI "PID eq %d"', $pid));
            if (count(preg_split("/\n/", $process)) > 4 && !preg_match('/INFO: No tasks are running which match the specified criteria./', $process)) {
                return true;
            }
        } else if ($os === "Linux") {
            $process = shell_exec(sprintf('ps %d 2>&1', $pid));
            if (count(preg_split("/\n/", $process)) > 2 && !preg_match('/ERROR: Process ID out of range/', $process)) {
                return true;
            }
        }
        return false;
    }

    public function isProcessHasError ($file_id) {
        $dir = base_path('resources/data/'.$file_id);
        $error_file = @file_get_contents($dir."/error.txt");
        $metrics = json_decode(@file_get_contents($dir."/metrics.json"));
        
        if ($error_file && !$metrics) {
            return true;
        }

        return false;
    }

    public function updateProcess ($file_id, $status_id) {
        File::where('id', $file_id)->update([
            'status_id' => $status_id,
            'pid' => null,
        ]);
    }
}
