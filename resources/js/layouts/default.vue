<template>
  <div class="main-layout">
    <navbar/>

    <div class="container mt-4">
      <child/>
    </div>
    <copyright/>
  </div>
</template>

<script>
import Navbar from '~/components/Navbar'
import Copyright from '~/components/Copyright'

export default {
  name: 'MainLayout',

  components: {
    Navbar,
    Copyright
  }
}
</script>
