<?php

use Illuminate\Database\Seeder;
use App\User;

class UsersTableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        //
        User::insert([
        	'name' => 'Surado',
        	'email' => 'fksutan.rajomudo@gmail.com',
        	'password' => '$2y$10$0WjAgtR0nqeIR9.yY0DdTuUj3z2bjgagpUbNNxfTnG.0paLiI9Wwu',
        	'activation' => true,
        	'created_at' => date('Y-m-d H:i:s')
        ]);
    }
}
