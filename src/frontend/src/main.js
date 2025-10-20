import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import Vue3Toastify from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

// Vuetify for matrix CRUD components
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import 'vuetify/styles'
import '@mdi/font/css/materialdesignicons.css'

import App from './App.vue'
import './assets/styles/main.css'
import { useAuthStore } from './stores/auth'

const app = createApp(App)
const pinia = createPinia()

// Element Plus icons
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

// Configure Vuetify for CRUD components
const vuetify = createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'dark',
    themes: {
      dark: {
        colors: {
          primary: '#2ba3c8',
          secondary: '#1e1e1e',
          background: '#121212'
        }
      }
    }
  }
})

app.use(pinia)
app.use(router)
app.use(ElementPlus)
app.use(vuetify)
app.use(Vue3Toastify, {
  autoClose: 3000,
  position: 'top-right',
  hideProgressBar: false,
  closeOnClick: true,
  pauseOnHover: true,
  theme: 'light'
})

// Initialize auth state before mounting app
const authStore = useAuthStore()
authStore.initialize().then(() => {
  app.mount('#app')
})