<template>
  <card>
    <template v-if="is_load">
      <vue-content-loading :width="400" :height="120">
        <rect x="0" y="0" rx="4" ry="4" width="200" height="25" />
        <rect x="0" y="30" rx="4" ry="4" width="400" height="12" />
        <rect x="0" y="45" rx="4" ry="4" width="400" height="12" />
        <rect x="0" y="60" rx="4" ry="4" width="400" height="12" />
        <rect x="0" y="75" rx="4" ry="4" width="400" height="12" />
        <rect x="0" y="90" rx="4" ry="4" width="400" height="12" />
      </vue-content-loading>
    </template>
    <template v-else>
      <h3>Analysis status of '{{ result.file.project_name }}'</h3><hr class="m-0 pb-2"/>
      <div id="process-meta" class="pb-2">
        <table>
          <tr>
            <td>{{ $t('status' )}}</td>
            <td class="colon">:&nbsp;&nbsp;</td>
            <td>{{ result.file.process_status.name }}</td>
          </tr>
          <tr>
            <td>{{ $t('organism' )}}</td>
            <td class="colon">:&nbsp;&nbsp;</td>
            <td>{{ result.file.organism }}</td>
          </tr>
          <tr>
            <td>{{ $t('snp_data' )}}</td>
            <td class="colon">:&nbsp;&nbsp;</td>
            <td>{{ result.file.snps_data }}</td>
          </tr>
          <tr>
            <td>{{ $t('phenotype_data' )}}</td>
            <td class="colon">:&nbsp;&nbsp;</td>
            <td>{{ result.file.phenotype_data }}</td>
          </tr>
          <tr v-if="result.file.status_id === 1"> <!-- uploaded -->
            <td>{{ $t('running_date') }}</td>
            <td class="colon">:&nbsp;&nbsp;</td>
            <td>{{ result.file.created_at }}</td>
          </tr>
          <tr v-else-if="result.file.status_id === 2"> <!-- running -->
            <td>{{ $t('running_date') }}</td>
            <td class="colon">:&nbsp;&nbsp;</td>
            <td>{{ result.file.updated_at }} ({{ time }} elapsed)</td>
          </tr>
          <tr v-else-if="result.file.status_id === 3"> <!-- finished -->
            <td>{{ $t('finished_date') }}</td>
            <td class="colon">:&nbsp;&nbsp;</td>
            <td>{{ result.file.updated_at }}</td>
          </tr>
        </table>
        <!-- TO DO: add begin analysis button if status_id = 1, and stop button if status_id = 2 -->
      </div>
      <div v-if="result.file.status_id === 3" id="process-result" class="pb-2">
        <h5 class="p-0 btn btn-link btn-lg btn-block text-left" data-toggle="collapse" href="#result" role="button" aria-expanded="false" aria-controls="collapseExample">
          Result <fa icon="caret-square-down" fixed-width/>
        </h5>
        <div class="result collapse show" id="result">
          <div class="row m-auto"> 
            <div class="col-md-8">
              <table class="table table-striped table-hover table-custom">
                <caption>List of predicted SNPs associated to phenotype '{{ result.metrics.phenotype }}'</caption>
                <thead>
                  <tr>
                    <th>SNPs ID</th>
                    <th>Rank</th>
                    <th>Chromosome</th>
                    <th>Position</th>
                  </tr>
                </thead>
                <tbody>
                <tr v-for="(snp, index) in result.result" :key=index>
                  <td>{{ snp.snp }}</td>
                  <td>{{ snp.rank }}</td>
                  <td>{{ snp.chr }}</td>
                  <td>{{ snp.pos }}</td>
                </tr>
                </tbody>
              </table>
            </div>
            <div class="col-md-4">
              Metrics: <br/>
              <b>- Adjusted R<sup>2</sup></b>: {{ toPercent(result.metrics.adjR2) }} <br/>
              <b>- Mean square error</b>: {{ toPercent(result.metrics.mse) }} <br/>
            </div>
          </div>
        </div>
      </div>
      <div v-if="result.file.status_id > 1" id="process-log">
        <h5 class="p-0 btn btn-link btn-lg btn-block text-left" data-toggle="collapse" href="#log" role="button" aria-expanded="false" aria-controls="collapseExample">
          Process log <fa icon="caret-square-down" fixed-width/>
        </h5>
        <div class="log p-2 collapse" :class="{ 'show': result.file.status_id == 2}" id="log">
          <code><pre style="overflow-x: scroll;">{{ result.log }}</pre></code>
        </div>
      </div>
    </template>
  </card>
</template>

<script>
import Form from 'vform'
import { mapGetters } from 'vuex'
import axios from 'axios'
import VueContentLoading from 'vue-content-loading'

export default {
  scrollToTop: false,

  middleware: 'active-account',
  
  components: {
    VueContentLoading
  },

  metaInfo () {
    return { title: this.$t('submission') }
  },

  data: () => ({
      hash_id: null,
      result: {},
      is_load: true,
      time: '',
      time_ticker: '',
      result_refresher: '',
  }),

  computed: mapGetters({
    user: 'auth/user'
  }),

  mounted () {
      this.hash_id = this.$route.params.hash_id
      this.get(false)
  },

  beforeDestroy () {
    clearInterval(this.time_ticker)
    clearInterval(this.result_refresher)
  },

  methods: {
    async get (refresh = true) {
      try {
        const { data } = await axios.get('/api/submission/get/'+this.hash_id)
        this.result = data
        this.is_load = false
  // concern: Timezone, time elapsed better handle by server instead of client
        if (!refresh && this.result.file.status_id == 2) {
          this.timeDiff()
          this.time_ticker = setInterval(this.timeDiff, 1000)
          this.result_refresher = setInterval(this.get, 5000)
        } else if (this.result.file.status_id > 2) {
          clearInterval(this.time_ticker)
          clearInterval(this.result_refresher)
        }
      } catch (error) {
        console.error(error.response)
      }
    },

    timeDiff () {
      let curr_time = new Date()
      let past_time = new Date(this.result.file.updated_at)

      let elapsed_time = (curr_time - past_time)/1000
      if(elapsed_time <= 60) {
        this.time = Math.round(elapsed_time)+" seconds"
      }else if(elapsed_time <= 3600){
        this.time = Math.round(elapsed_time/60)+" minutes"
      }else if(elapsed_time <= 86400){
        this.time = Math.round(elapsed_time/3600)+" hours"
      }else{
        this.time = Math.round(elapsed_time/86400)+" days"
      }
    },

    toPercent (val) {
      return Number(val).toFixed(2)*100+"%"
    }
  }
}
</script>
<style scoped>
.log {
  background-color: #efefef;
}
.result {
  border: solid 1px #343A40;
  border-radius: 0.1em;
  padding: 0.5em;
}

/* Smartphones (portrait and landscape) ----------- */
@media only screen 
and (min-device-width : 320px) 
and (max-device-width : 480px) {
    .table-custom {
      display: block;
      width: 100%;
      overflow-x: auto;
      -webkit-overflow-scrolling: touch;
      -ms-overflow-style: -ms-autohiding-scrollbar;
    }
}
</style>

