<?php

use Illuminate\Http\Request;
use App\File;

Route::get('/testfile', function (Request $request) {
    return str_replace("\\", "/", base_path());
});

Route::group(['middleware' => 'auth:file'], function () {
    Route::group(['middleware' => 'active.account:file'], function () {
        Route::get('/file-{hashid}/{filename}', function (Request $request) {
            $file = File::where([['user_id', '=', $request->user()->id], ['hashid', '=', $request->hashid]])->firstOrFail();
            
            if (substr($request->filename, 0, 4) === "snps") {
                $file_loc = base_path('/resources/data/'.$request->hashid.'/'.$file->snps_data);
            } else if (substr($request->filename, 0, 5) === "pheno") {
                $file_loc = base_path('/resources/data/'.$request->hashid.'/'.$file->phenotype_data);
            } else {
                abort(404);
            }

            header('Content-Description: File Transfer');
            header('Content-Type: application/octet-stream');
            header('Content-Disposition: attachment; filename="'.basename($file_loc).'"');
            header('Expires: 0');
            header('Cache-Control: must-revalidate');
            header('Pragma: public');
            header('Content-Length: ' . filesize($file_loc));

            return readfile($file_loc);
        });
    });
});