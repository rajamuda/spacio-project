<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateSnpsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('snps', function (Blueprint $table) {
            $table->increments('id');
            $table->string('rs_id');
            $table->string('genotype');
            $table->string('position');
            $table->string('chromosome');
            $table->integer('data_id')->unsigned();
            $table->timestamps();

            $table->foreign('data_id')
                ->references('id')
                ->on('uploads')
                ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('snps');
    }
}
