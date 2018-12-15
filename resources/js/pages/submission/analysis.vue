<template>
  <card>
    <div v-if="is_load">
      <vue-content-loading :width="400" :height="105">
        <rect x="0" y="0" rx="4" ry="4" width="100" height="15" />
        <rect x="0" y="20" rx="4" ry="4" width="400" height="80" />
      </vue-content-loading>
    </div>
    <div v-else>
      <div class="text-center" v-if="!running.length && !uploaded.length && !finished.length">
        {{ $t('no_file') }}<br/>
        <router-link :to="{ name: 'submission.add' }">Add new file</router-link>
      </div>
      <div v-if="running.length">
        <h5>{{ $t('running_status') }}</h5>
        <div v-for="(data, index) in running" :key="index">
          <div class="card border-custom mb-3 mt-2">	
            <router-link :to="{ name: 'submission.result', params: { hash_id: data.hashid }}">
              <div class="card-header text-white bg-custom">{{ data.project_name }} ( {{ $t('running') }} )</div>
            </router-link>
            <div class="card-body text-dark">
              <div class="process-status">
                <table>
                  <tr>
                    <td>{{ $t('organism' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.organism }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('snp_data' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.snps_data }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('phenotype_data' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.phenotype_data }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('running_date') }}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.updated_at }}</td>
                  </tr>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-if="uploaded.length">
        <h5>{{ $t('uploaded_status') }}</h5>
        <div v-for="(data, index) in uploaded" :key="index">
          <div class="card border-custom mb-3 mt-2">	
            <router-link :to="{ name: 'submission.result', params: { hash_id: data.hashid }}">
              <div class="card-header text-white bg-custom">{{ data.project_name }}</div>
            </router-link>
            <div class="row card-body text-dark">
              <div class="col-8 process-status">
                <table>
                  <tr>
                    <td>{{ $t('organism' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.organism }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('snp_data' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.snps_data }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('phenotype_data' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.phenotype_data }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('uploaded_date') }}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.created_at }}</td>
                  </tr>
                </table>
              </div>
              <div class="col-4 m-auto">
                <button class="btn btn-success" @click="beginAnalysis(data.hashid)"><fa icon="play" fixed-width/> Begin Analysis</button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-if="finished.length">
        <h5>{{ $t('finished_status') }}</h5>
        <div v-for="(data, index) in finished" :key="index">
          <div class="card border-custom mb-3 mt-2">	
            <router-link :to="{ name: 'submission.result', params: { hash_id: data.hashid }}">
              <div class="card-header text-white bg-custom">{{ data.project_name }}</div>
            </router-link>
            <div class="card-body text-dark">
              <div class="process-status">
                <table>
                  <tr>
                    <td>{{ $t('organism' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.organism }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('snp_data' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.snps_data }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('phenotype_data' )}}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.phenotype_data }}</td>
                  </tr>
                  <tr>
                    <td>{{ $t('uploaded_date') }}</td>
                    <td class="colon">:&nbsp;&nbsp;</td>
                    <td>{{ data.created_at }}</td>
                  </tr>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
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
    uploaded: [],
    running: [],
    finished: [],
    is_load: true,
  }),

  computed: mapGetters({
    user: 'auth/user'
  }),

  mounted () {
    this.getAll()
  },

  methods: {
    async getAll () {
      try {
        const { data } = await axios.get('/api/submission/get-all')
        this.uploaded = data.file.uploaded
        this.running = data.file.running
        this.finished = data.file.finished
        this.is_load = false
      } catch (error) {
        console.error(error)
      }
    },

    beginAnalysis (hashid) {
      axios.post('/api/submission/run-analysis', { file_id: hashid })
        .then(({data}) => {
          console.log(data)
          this.$router.push({ name: 'submission.result', params: { hash_id: hashid } })
        }).catch((error) => {
          console.error(error.response)
        })
    },
  }
}
</script>

<style scoped>
  .bg-custom {
    background-color: #343A40;
  }
  .border-custom {
    border-color: #343A40;
  }
</style>
