<script setup>
import { useRouter } from 'vue-router'
const router = useRouter()

const navigateToSurvey = () => {
  router.push('/SurveyUserCreate')
}
</script>

<template>
  <v-app>
    <v-container
      fluid
      class="d-flex flex-column"
      style="min-height: 100vh; background-color: #121212;"
    >
      <h1 class="welcome-text">
        Welcome to Systems Engineering Competency Assessment Survey
      </h1>

      <v-row justify="center" class="mt-10">
        <v-col cols="12" sm="6" md="4" class="mx-auto d-flex justify-center">
          <div class="monitor" @click="navigateToSurvey">
            <div class="monitor-screen">
              <span class="monitor-text">Take Survey</span>
            </div>
            <div class="monitor-led"></div>
          </div>
        </v-col>
      </v-row>
    </v-container>
  </v-app>
</template>

<style scoped>
.welcome-text {
  color: white;
  font-family: 'Roboto', sans-serif;
  font-size: 3rem;
  text-align: center;
  margin-top: 2rem;
}

.monitor {
  position: relative;
  /* Let the width be responsive, but with a 4:3 aspect ratio for a more classic CRT shape */
  width: 100%;
  max-width: 320px;
  max-height: 200px;
  aspect-ratio: 4 / 3;
  background: #333;
  border: 8px solid #444;
  border-radius: 8px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.6);
  cursor: pointer;
}

.monitor-screen {
  position: absolute;
  top: 10%;
  left: 8%;
  width: 84%;
  height: 70%;
  background: #000;
  border: 2px solid #222;
  border-radius: 4px;
  box-shadow: inset 0 0 10px #000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.monitor-text {
  color: #0f0;
  font-family: monospace;
  font-size: 1.3rem;
  text-shadow: 0 0 5px #0f0;
}

.monitor-led {
  position: absolute;
  bottom: 6%;
  left: 8%;
  width: 10px;
  height: 10px;
  background: #900;
  border-radius: 50%;
  box-shadow: 0 0 5px 2px #f00;
}
</style>
