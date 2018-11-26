<template>
  <card>
    <div class="m-auto p-4">
      <div class="form-group row">
        <label class="col-md-3 col-form-label">Project's Name</label>
        <input type="text" v-model="projectName" name="projectName" class="col-md-8 form-control">
      </div>
      <div class="row">
        <h5 class="col-md-12">Upload CSV Data</h5>
      </div>
      <div class="row m-0" style="background-color: #efefef">
        <div class="form-group col-md-6">
          <label class="col-md-12 col-form-label">SNPs Data</label>
          <input type="file" id="snps" class="col-md-12 form-control-file" accept="text/csv" @change="uploadFieldChange($event, 'snps')">
          <span v-if="snps.length" class="col-md-12 text-muted">Size: {{ getFileSize('snps') }}</span>
        </div>
        <div class="form-group col-md-6">
          <label class="col-md-12 col-form-label">Phenotype Measure</label>
          <input type="file" id="phenotype" class="col-md-12 form-control-file" accept="text/csv" @change="uploadFieldChange($event, 'phenotype')">
          <span v-if="phenotype.length" class="col-md-12 text-muted">Size: {{ getFileSize('phenotype') }}</span>
        </div>
        <div v-if="percentCompleted > 0" class="progress col-md-12 mb-2">
          <div class="progress-bar progress-bar-striped" :class="{'bg-success': (percentCompleted == 100), 'bg-danger': (errors != '')}" role="progressbar" :style="{width: percentCompleted + '%'}" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"> {{ percentCompleted }}% </div>
        </div>   
      </div>
      <!-- Parameter settings -->
      <div id="accordion">

          <div id="headingOne">
            <h5 class="mb-0">
              <button class="p-0 btn btn-link" data-toggle="collapse" data-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
                <fa icon="caret-square-down" fixed-width/> Advanced settings
              </button>
            </h5>
          </div>
        <div class="px-2">
          <div id="collapseOne" class="collapse" aria-labelledby="headingOne" data-parent="#accordion">
            <div class="row mx-auto">
              <div class="col-md-6">Minor Allele Frequency (MAF)</div>
              <div class="col-md-2"><input type="text" class="form-control form-control-sm" name="maf" value="0.01"/></div>
            </div> 
            <div class="row mx-auto">
              <div class="col-md-6">Minimum SNPs to process</div>
              <div class="col-md-2"><input type="text" class="form-control form-control-sm" name="maf" value="100"/></div>
            </div>      
            <div class="row mx-auto">
              <div class="col-md-6">Remove Monomorphism</div>
              <div class="col-md-2 text-right"><input type="checkbox" class="form-check-input" name="monomorphism" checked/></div>
            </div>
            <div class="row mx-auto">
              <div class="col-md-6">Only use highly ranked SNPs</div>
              <div class="col-md-2 text-right"><input type="checkbox" class="form-check-input" name="ranked" checked/></div>
            </div>                       
          </div>
        </div>
      </div>
      <div class="form-group pt-4 px-0 col-md-12">
        <button class="btn btn-success" @click="submit">Upload</button>
      </div>   
    </div>
  </card>
</template>

<script>
import { mapGetters } from 'vuex'
import axios from 'axios'

export default {
  scrollToTop: false,

  metaInfo () {
    return { title: this.$t('submission') }
  },

  data: () => ({
    snps: [],
    phenotype: [],
    projectName: '',
    formData: new FormData(),
    errors: '',
    percentCompleted: 0
  }),

  computed: mapGetters({
    user: 'auth/user'
  }),

  methods: {
    getFileSize(type) {
      if(type === 'snps' && this.snps.length)
        return this.snps[0].size;
      else if(type === 'phenotype' && this.phenotype.length)
        return this.phenotype[0].size;
      // this.upload_size = 0; // Reset to beginningƒ
      // this.snps.map((item) => { this.upload_size += parseInt(item.size); });

      // this.upload_size = Number((this.upload_size).toFixed(1));
      // this.$forceUpdate();
    },

    prepareFields() {
      if(this.snps.length && this.phenotype.length && this.projectName){
        this.formData.append('file[0]', this.snps[0])
        this.formData.append('file[1]', this.phenotype[0])
        this.formData.append('projectName', this.projectName)
        return true
      }

      return false
    },

    // This function will be called every time you add a file
    uploadFieldChange(e, type) {
      var file = e.target.files || e.dataTransfer.files
      if (!file.length) return

      if(type === 'snps') this.snps.push(file[0])
      else if(type === 'phenotype') this.phenotype.push(file[0])
      else return
    },

    submit() {
      if(this.prepareFields()){
        this.errors = '';
        var config = {
          headers: { 'Content-Type': 'multipart/form-data' } ,
          onUploadProgress: function(progressEvent) {
            this.percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total)
            this.$forceUpdate()
          }.bind(this)
        };
        // // Make HTTP request to store announcement
        axios.post('/api/test/upload', this.formData, config)
          .then(function (response) {
            console.log(response)
            // if (response.data.success) {
            //   console.log('Successfull Upload')
            //   this.resetData()
            // } else {
            //   console.log('Unsuccessful Upload')
            //   this.errors = response.data.errors
            // }
          }).bind(this) // Make sure we bind Vue Component object to this funtion so we get a handle of it in order to call its other methods
          .catch(function (error) {
            console.log(error);
          });
      } else {
        this.errors = "Specified field or file not inputed yet"
      }
    },

    // We want to clear the FormData object on every upload so we can re-calculate new files again.
    // Keep in mind that we can delete files as well so in the future we will need to keep track of that as well
    resetData() {
      this.formData = new FormData(); // Reset it completely

      this.snps = [];
    },
  }
}
</script>
