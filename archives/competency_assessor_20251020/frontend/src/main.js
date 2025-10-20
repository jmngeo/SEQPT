import { createApp } from 'vue';
import App from './App.vue';
import { createPinia } from 'pinia';
import router from './router'; // Import the router

// Vuetify imports
import { createVuetify } from 'vuetify';
import 'vuetify/styles'; // Import Vuetify styles
import '@mdi/font/css/materialdesignicons.css'; // Import Material Design Icons
import * as components from 'vuetify/components'; // Import Vuetify components
import * as directives from 'vuetify/directives'; // Import Vuetify directives

// Create the Vuetify instance with dark theme as default
const vuetify = createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'dark', // Set the default theme to dark
    themes: {
      dark: {
        colors: {
          primary: '#1E88E5', // Customize primary color in dark theme
          secondary: '#424242', // Customize secondary color in dark theme
        },
      },
    },
  },
});

const app = createApp(App);
const pinia = createPinia();
// Use Vue Router and Vuetify in the app
app.use(router);
app.use(vuetify);
app.use(pinia);
// Mount the app to the DOM
app.mount('#app');
