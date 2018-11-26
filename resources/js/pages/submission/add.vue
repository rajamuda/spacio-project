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

  metaInfo () {
    return { title: this.$t('settings') }
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
