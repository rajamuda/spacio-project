<template>
  <card v-if="!active_account" class="text-center">
    <fa icon="times-circle" size="9x"/>
    <div class="p-2">Access is not permitted. <br/> <b>Reason:</b> Your account is not activated yet.</div>
  </card>
</template>

<script>
import Form from 'vform'
import { mapGetters } from 'vuex'

export default {
  scrollToTop: false,

  middleware: 'auth',

  metaInfo () {
    return { title: this.$t('submission') }
  },

  computed: mapGetters({
    active_account: 'auth/active_account'
  }),

  created () {
    if(this.active_account){
      this.$router.push({ name: 'submission.add' })
    }
  }

}
</script>
