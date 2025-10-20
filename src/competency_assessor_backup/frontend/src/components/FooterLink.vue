<template>
  <div class="footer-link">
    <a href="https://www.fraunhofer.de/de/impressum.html" target="_blank" rel="noopener noreferrer">
      Datenschutz Impressum
    </a>
  </div>
</template>

<script setup>
</script>

<style scoped>
.footer-link {
  position: fixed;
  bottom: 10px;
  left: 10px;
  font-size: 0.8rem; /* Small font size */
  color: white;
}

.footer-link a {
  color: white;
  text-decoration: none;
}

.footer-link a:hover {
  text-decoration: underline;
}
</style>
