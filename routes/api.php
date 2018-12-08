<?php

use Illuminate\Http\Request;
use Hashids\Hashids; // <- using PHP BC Math extension

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::group(['middleware' => 'auth:api'], function () {
    Route::post('logout', 'Auth\LoginController@logout');

    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::patch('settings/profile', 'Settings\ProfileController@update');
    Route::patch('settings/password', 'Settings\PasswordController@update');

    Route::post('test/upload', function (Request $request) {
        dd($request);
    });

    Route::group(['middleware' => 'active.account:api'], function () {
        Route::get('test/account', function (Request $request) {
            echo "SAFE!";
        });

        Route::post('submission/upload', 'SubmissionController@upload');
    });
});

Route::group(['middleware' => 'guest:api'], function () {
    Route::post('login', 'Auth\LoginController@login');
    Route::post('register', 'Auth\RegisterController@register');
    Route::post('password/email', 'Auth\ForgotPasswordController@sendResetLinkEmail');
    Route::post('password/reset', 'Auth\ResetPasswordController@reset');

    Route::post('oauth/{driver}', 'Auth\OAuthController@redirectToProvider');
    Route::get('oauth/{driver}/callback', 'Auth\OAuthController@handleProviderCallback')->name('oauth.callback');

    Route::get('test/hashid', function (Request $request) {
        $id = $request->query('id');

        $hashid = new Hashids(
                    config('app.hashid.secret'), 
                    config('app.hashid.padding'), 
                    config('app.hashid.characters')
                );
        // $enc = $hashid->encode($id);
        $dec = $hashid->decode($id);
        print_r($dec);

        // echo $enc."<br/>\n";
        // echo $dec[0]."\n";
        // $file = "/home/surado/htdocs/spacio-project/resources/data/result.csv";
        // $csv= file_get_contents($file);
        // $array = array_map("str_getcsv", explode("\n", $csv));
        // $json = json_encode($array);
        // print_r($array);
        // $a = "Xy2nasj2";
        // echo base_path('resources/data/'.$a);
    });
});
