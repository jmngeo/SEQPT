<template>
  <v-card>
    <v-card-title>
      <v-icon class="mr-2">mdi-chart-tree</v-icon>
      Organization Structure Analysis
    </v-card-title>

    <v-card-subtitle v-if="analysis">
      {{ analysis.summary }}
    </v-card-subtitle>

    <v-card-text>
      <v-alert type="info" variant="tonal" class="mb-4">
        <strong>About this analysis:</strong> This shows which SE role clusters are present in your organization.
        This is descriptive information only - organizations naturally have different role structures based on their
        size, industry, and business model.
      </v-alert>

      <!-- Loading State -->
      <v-progress-linear v-if="loading" indeterminate color="primary" class="mb-4"></v-progress-linear>

      <!-- Analysis Results -->
      <div v-if="!loading && analysis">
        <!-- Summary Statistics -->
        <v-row class="mb-4">
          <v-col cols="12" md="6">
            <v-card variant="outlined">
              <v-card-text>
                <div class="text-h4 text-primary">{{ analysis.present_clusters_count }}</div>
                <div class="text-caption text-grey">Role Clusters Present</div>
              </v-card-text>
            </v-card>
          </v-col>
          <v-col cols="12" md="6">
            <v-card variant="outlined">
              <v-card-text>
                <div class="text-h4 text-grey">{{ analysis.total_possible_clusters }}</div>
                <div class="text-caption text-grey">Total SE-QPT Clusters</div>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>

        <!-- Present Clusters -->
        <h3 class="mb-3">Present Role Clusters</h3>
        <v-expansion-panels variant="accordion" class="mb-4">
          <v-expansion-panel
            v-for="cluster in analysis.present_clusters"
            :key="cluster.id"
          >
            <v-expansion-panel-title>
              <div class="d-flex align-center justify-space-between w-100">
                <div>
                  <v-icon class="mr-2" color="success">mdi-check-circle</v-icon>
                  <strong>{{ cluster.name }}</strong>
                </div>
                <v-chip size="small" color="primary" class="mr-2">
                  {{ cluster.org_roles.length }} role(s)
                </v-chip>
              </div>
            </v-expansion-panel-title>

            <v-expansion-panel-text>
              <!-- Cluster Description -->
              <p class="text-caption text-grey mb-3">{{ cluster.description }}</p>

              <!-- Organization Roles in this Cluster -->
              <v-list density="compact">
                <v-list-subheader>Your organization's roles in this cluster:</v-list-subheader>
                <v-list-item
                  v-for="(role, index) in cluster.org_roles"
                  :key="index"
                >
                  <template v-slot:prepend>
                    <v-icon size="small">mdi-account</v-icon>
                  </template>

                  <v-list-item-title>{{ role.title }}</v-list-item-title>

                  <template v-slot:append>
                    <v-chip
                      size="x-small"
                      :color="getConfidenceColor(role.confidence)"
                    >
                      {{ role.confidence }}% match
                    </v-chip>
                  </template>
                </v-list-item>
              </v-list>
            </v-expansion-panel-text>
          </v-expansion-panel>
        </v-expansion-panels>

        <!-- Visual Representation -->
        <h3 class="mb-3">Visual Overview</h3>
        <v-card variant="outlined" class="pa-4">
          <v-row>
            <v-col
              v-for="cluster in allClusters"
              :key="cluster.id"
              cols="6"
              sm="4"
              md="3"
            >
              <v-card
                :color="isClusterPresent(cluster.id) ? 'success' : 'grey-lighten-3'"
                :variant="isClusterPresent(cluster.id) ? 'tonal' : 'outlined'"
                class="text-center pa-2"
              >
                <v-icon
                  :color="isClusterPresent(cluster.id) ? 'success' : 'grey'"
                  size="large"
                >
                  {{ isClusterPresent(cluster.id) ? 'mdi-check-circle' : 'mdi-circle-outline' }}
                </v-icon>
                <div class="text-caption mt-2">{{ cluster.name }}</div>
                <div
                  v-if="isClusterPresent(cluster.id)"
                  class="text-caption font-weight-bold text-success"
                >
                  {{ getClusterRoleCount(cluster.id) }} role(s)
                </div>
              </v-card>
            </v-col>
          </v-row>
        </v-card>
      </div>

      <!-- Empty State -->
      <v-alert v-if="!loading && !analysis" type="warning" variant="tonal">
        No organization structure analysis available. Please map your roles first.
      </v-alert>
    </v-card-text>

    <v-card-actions>
      <v-btn @click="refreshAnalysis" :loading="loading">
        <v-icon class="mr-2">mdi-refresh</v-icon>
        Refresh Analysis
      </v-btn>
      <v-spacer></v-spacer>
      <v-btn color="primary" @click="$emit('close')">
        Close
      </v-btn>
    </v-card-actions>
  </v-card>
</template>

<script>
import axios from 'axios'

export default {
  name: 'OrganizationStructureAnalysis',

  props: {
    organizationId: {
      type: Number,
      required: true
    }
  },

  emits: ['close'],

  data() {
    return {
      loading: false,
      analysis: null,
      allClusters: []
    }
  },

  mounted() {
    this.loadAnalysis()
    this.loadAllClusters()
  },

  methods: {
    async loadAnalysis() {
      this.loading = true
      try {
        const response = await axios.get(`/api/phase1/organization-structure/${this.organizationId}`)
        if (response.data.success) {
          this.analysis = response.data.analysis
        }
      } catch (error) {
        console.error('Error loading organization structure:', error)
      } finally {
        this.loading = false
      }
    },

    async loadAllClusters() {
      try {
        const response = await axios.get('/api/phase1/role-clusters')
        if (response.data.success) {
          this.allClusters = response.data.role_clusters
        }
      } catch (error) {
        console.error('Error loading role clusters:', error)
      }
    },

    refreshAnalysis() {
      this.loadAnalysis()
    },

    isClusterPresent(clusterId) {
      if (!this.analysis) return false
      return this.analysis.present_clusters.some(c => c.id === clusterId)
    },

    getClusterRoleCount(clusterId) {
      if (!this.analysis) return 0
      const cluster = this.analysis.present_clusters.find(c => c.id === clusterId)
      return cluster ? cluster.org_roles.length : 0
    },

    getConfidenceColor(confidence) {
      if (confidence >= 80) return 'success'
      if (confidence >= 60) return 'info'
      if (confidence >= 40) return 'warning'
      return 'error'
    }
  }
}
</script>

<style scoped>
.w-100 {
  width: 100%;
}
</style>
