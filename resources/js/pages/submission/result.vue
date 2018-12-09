<template>
  <card>
    {{ hash_id }}
  </card>
</template>

<script>
import Form from 'vform'
import { mapGetters } from 'vuex'

export default {
  scrollToTop: false,

  middleware: 'active-account',
    
  metaInfo () {
    return { title: this.$t('submission') }
  },

  data: () => ({
      hash_id: null
  }),

  computed: mapGetters({
    user: 'auth/user'
  }),

  created () {
      this.hash_id = this.$route.params.hash_id
  },

  methods: {

  }
}
</script>
