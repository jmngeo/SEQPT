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
  font-size: 0.8rem;
  z-index: 1000;
}

.footer-link a {
  color: #909399;
  text-decoration: none;
  padding: 4px 8px;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.footer-link a:hover {
  text-decoration: underline;
  color: #409eff;
  background: rgba(255, 255, 255, 1);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
}
</style>