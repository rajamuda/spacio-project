<template>
  <!-- <card :title="$t('home')"> -->
  <card :class="'p-5'">
    <!-- {{ $t('welcome') }} -->
  <div class="m-auto">
	  <div class="row">
	    <div class="h5 col-md-6 offset-md-2 px-0 py-3 m-auto d-flex">
	      Search something,
	    </div>
	  </div>
    <div class="row">
      <div class="col-md-6 m-auto">
        <form @submit.prevent="search">
          <div class="input-group row">
            <input v-model="form.search" type="text" class="form-control" name="search" placeholder="Type something... (e.g SNP rsID or phenotypte criteria)">
            <div class="input-group-append">
				      <button class="btn btn-success" type="button">
				        <fa icon="search" fixed-width/>
				      </button>
			   	 	</div>
          </div>
        </form>
      </div>
    </div>
  </div>
  </card>
</template>

<script>
import Form from 'vform'

export default {
  // middleware: 'auth',

  metaInfo () {
    return { title: this.$t('home') }
  },

  data: () => ({
  	form: new Form({
  		search: '',
  	})
  }),

  methods: {
  	search () {
  		console.log("You type "+this.form.search)
  	}
  }
}
</script>
