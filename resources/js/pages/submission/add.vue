<template>
  <card>
    <div class="m-auto p-4">
      <div ref="error-message">
        <div v-if="errors != ''" class="alert alert-danger"><fa icon="times-circle" fixed-width/> {{ errors.message }}</div>
      </div>
      <div class="form-group row">
        <label class="col-md-3 col-form-label">{{ $t('submission_name') }}</label>
        <input type="text" v-model="project_name" name="project_name" class="col-md-8 form-control">
      </div>
      <div class="form-group row">
        <label class="col-md-3 col-form-label">{{ $t('organism') }}</label>
        <input type="text" v-model="organism" name="organism" class="col-md-8 form-control">
      </div>
      <div class="row">
        <h5 class="col-md-12">{{ $t('upload_csv') }}</h5>
      </div>
      <div class="row m-0" style="background-color: #efefef">
        <div class="form-group col-md-6">
          <label class="col-form-label">{{ $t('snp_data') }}</label>
          <div class="input-upload mx-0 btn btn-upload btn-block">
            <fa icon="folder-open" fixed-width/>
            {{ $t('choose_file') }}
            <input type="file" id="snps" class="form-control-file" accept="text/csv" @change="uploadFieldChange($event, 'snps')">
          </div>
          <template v-if="snps.length">
            <div class="col-md-12 text-muted">{{ snps[0].name }}</div>
            <div class="col-md-12 text-muted">{{ $t('size') }}: {{ getFileSize('snps') }} MB</div>
          </template>
        </div>
        <div class="form-group col-md-6">
          <label class="col-form-label">{{ $t('phenotype_data') }}</label>
          <div class="input-upload mx-0 btn btn-upload btn-block">
            <fa icon="folder-open" fixed-width/>
            {{ $t('choose_file') }}
            <input type="file" id="phenotype" class="form-control-file" accept="text/csv" @change="uploadFieldChange($event, 'phenotype')">
          </div> 
          <template v-if="phenotype.length"> 
            <div class="col-md-12 text-muted">{{ phenotype[0].name }}</div>
            <div class="col-md-12 text-muted">{{ $t('size') }}: {{ getFileSize('phenotype') }} MB</div>
          </template>
        </div>
        <div v-if="percent_completed > 0" class="progress col-md-12 mb-2">
          <div class="progress-bar progress-bar-striped" :class="{'bg-success': (percent_completed == 100), 'bg-danger': (errors != '')}" role="progressbar" :style="{width: percent_completed + '%'}" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"> {{ percent_completed }}% </div>
        </div>   
      </div>
      <!-- Parameter settings -->
      <div id="accordion">

          <div id="headingOne">
            <h5 class="mb-0">
              <button class="p-0 btn btn-link" data-toggle="collapse" data-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
                <fa icon="caret-square-down" fixed-width/> {{ $t('advanced_settings') }}
              </button>
            </h5>
          </div>
        <div class="px-2">
          <div id="collapseOne" class="collapse" aria-labelledby="headingOne" data-parent="#accordion">
            <div class="row mx-auto">
              <div class="col-md-6"># Nearest neighbor (k) for imputing missing values</div>
              <div class="col-md-2"><input type="text" class="form-control form-control-sm" name="nn" value="120"/></div>
            </div> 
            <div class="row mx-auto">
              <div class="col-md-6">Minimum SNPs to process</div>
              <div class="col-md-2"><input type="text" class="form-control form-control-sm" name="min-snps" value="100"/></div>
            </div>      
            <div class="row mx-auto">
              <div class="col-md-6">Only use highly ranked SNPs</div>
              <div class="col-md-2 text-right"><input type="checkbox" class="form-check-input" name="ranked" checked/></div>
            </div>
             <div class="row mx-auto">
              <div class="col-md-6">Immediately process the data when upload completed</div>
              <div class="col-md-2 text-right"><input type="checkbox" class="form-check-input" name="process-data-immediately" checked/></div>
            </div>                       
          </div>
        </div>
      </div>
      <div class="form-group pt-4 px-0 col-md-12">
        <button class="btn btn-success" :disabled="uploaded" @click="submit"><fa icon="upload" fixed-width/> {{ $t('upload') }}</button>
        <button class="btn" :class="{'btn-secondary': (percent_completed < 100), 'btn-primary': (percent_completed == 100)}" :disabled="percent_completed < 100"><fa icon="play" fixed-width/> {{ $t('begin_analysis') }}</button>
      </div>   
    </div>
  </card>
</template>

<script>
import { mapGetters } from 'vuex'
import axios from 'axios'

export default {
  scrollToTop: false,

  middleware: 'active-account',

  metaInfo () {
    return { title: this.$t('submission') }
  },

  data: () => ({
    snps: [],
    phenotype: [],
    project_name: '',
    organism: '',
    form_data: new FormData(),
    errors: '',
    percent_completed: 0,
    uploaded: false
  }),

  computed: mapGetters({
    user: 'auth/user'
  }),

  methods: {
    goToError () {
      let el = this.$refs['error-message']
      window.scrollTo(0, el.offsetTop)
    },
    
    getFileSize (type) {
      let size = 0
      if(type === 'snps' && this.snps.length)
        size = this.snps[0].size/(1024*1024)
      else if(type === 'phenotype' && this.phenotype.length)
        size = this.phenotype[0].size/(1024*1024)

      return size.toFixed(2)
    },

    prepareFields () {
      if(this.snps.length && this.phenotype.length && this.project_name && this.organism){
        this.form_data.append('snps', this.snps[0])
        this.form_data.append('phenotype', this.phenotype[0])
        this.form_data.append('project_name', this.project_name)
        this.form_data.append('organism', this.organism)
        return true
      }

      return false
    },

    // This function will be called every time you add a file
    uploadFieldChange (e, type) {
      var file = e.target.files || e.dataTransfer.files
      if (!file.length) return

      if(type === 'snps') { 
        this.snps = []
        this.snps.push(file[0])
      } else if(type === 'phenotype')  {
        this.phenotype = []
        this.phenotype.push(file[0])
      }
      else return
    },

    submit () {
      if(this.prepareFields() && !this.uploaded){
        this.errors = ''
        this.uploaded = true

        var config = {
          headers: { 'Content-Type': 'multipart/form-data' } ,
          onUploadProgress: function(progressEvent) {
            this.percent_completed = Math.round((progressEvent.loaded * 100) / progressEvent.total)
            this.$forceUpdate()
          }.bind(this)
        };
        // // Make HTTP request to store announcement
        axios.post('/api/submission/upload', this.form_data, config)
          .then(({data}) => {
            console.log(data)
          }).catch((error) => {
            console.error(error.response)
            this.uploaded = false
            this.errors = error.response.data
            this.goToError()
          });
      } else {
        this.errors = { message: "Specified field or file not inputed yet" }
        this.goToError()     
      }
    },

    // We want to clear the FormData object on every upload so we can re-calculate new files again.
    // Keep in mind that we can delete files as well so in the future we will need to keep track of that as well
    resetData () {
      this.form_data = new FormData() // Reset it completely
      this.snps = []
      this.phenotype = []
      this.percent_completed = 0
      this.uploaded = false
      this.errors = ''
    },
  }
}
</script>

<style scoped>
input[type=file] {
  position: absolute;
  top: 0;
  right: 0;
  margin: 0;
  padding: 0;
  font-size: 20px;
  cursor: pointer;
  opacity: 0;
  filter: alpha(opacity=0);
}
.input-upload {
  position: relative;
  overflow: hidden;
  margin: 10px;
}
</style>
