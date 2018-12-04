import store from '~/store'

export default async (to, from, next) => {
  if (!store.getters['auth/active_account']) {
    next({ name: 'submission.restricted' })
  } else {
    next()
  }
}
