<template>
	<footer class="footer">
		<div class="container text-center">
			<span class="text-muted">&copy; 2018 {{ appName }} &mdash; Bogor Agricultural University</span>
		</div>
	</footer>
</template>

<script>
export default {
	data: () => ({
		appName: window.config.appName
	})
}
</script>