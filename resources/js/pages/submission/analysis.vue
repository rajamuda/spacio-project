<template>
  <card>
    Nothing special
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

  }),

  computed: mapGetters({
    user: 'auth/user'
  }),

  created () {

  },

  methods: {

  }
}
</script>
