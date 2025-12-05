<template>
  <div class="role-mapper-container">
    <v-tabs v-model="tab" bg-color="transparent" class="mb-4">
      <v-tab value="file">
        <v-icon start>mdi-file-upload</v-icon>
        Upload Document
      </v-tab>
      <v-tab value="manual">
        <v-icon start>mdi-form-textbox</v-icon>
        Manual Entry
      </v-tab>
    </v-tabs>

    <div class="tabs-content">
      <!-- ========================================
           FILE UPLOAD TAB
           ======================================== -->
      <div v-show="tab === 'file'" class="tab-panel">
        <!-- Upload Area -->
        <div
          class="upload-dropzone"
          :class="{ 'is-processing': fileProcessing, 'has-file': uploadedFile }"
        >
          <v-file-input
            v-model="uploadedFile"
            accept=".pdf,.doc,.docx,.txt"
            @change="handleDocumentUpload"
            prepend-icon="mdi-cloud-upload"
            variant="solo"
            density="comfortable"
            hide-details
            :loading="fileProcessing"
          >
            <template v-slot:prepend>
              <v-icon size="48" color="primary">mdi-cloud-upload</v-icon>
            </template>
          </v-file-input>

          <div v-if="!uploadedFile && !fileProcessing" class="upload-instructions">
            <v-icon size="64" color="#909399">mdi-file-document-outline</v-icon>
            <h3>Upload Your Roles Document</h3>
            <p>Click to browse or drag and drop your file here</p>
            <p class="text-caption">Supported: PDF, DOCX, TXT</p>
          </div>

          <div v-if="fileProcessing" class="processing-state">
            <v-progress-circular indeterminate size="64" color="primary"></v-progress-circular>
            <h3>Processing Document...</h3>
            <p>Extracting roles using AI</p>
          </div>

          <div v-if="roles.length > 0 && !fileProcessing" class="success-state">
            <v-icon size="64" color="success">mdi-check-circle</v-icon>
            <h3>Successfully Extracted {{ roles.length }} {{ roles.length === 1 ? 'Role' : 'Roles' }}</h3>
            <p>Click "Start AI Mapping" below to map them to SE clusters</p>
          </div>
        </div>
      </div>

      <!-- ========================================
           MANUAL ENTRY TAB
           ======================================== -->

      <div v-show="tab === 'manual'" class="tab-panel">
        <div class="manual-entry-form">
          <v-text-field
            v-model="currentRole.title"
            label="Role Title"
            placeholder="e.g., Senior Software Engineer"
            variant="outlined"
            density="comfortable"
            hide-details
            class="mb-4"
          ></v-text-field>

          <v-textarea
            v-model="currentRole.description"
            label="Role Description"
            placeholder="Brief description of what this role does in your organization"
            rows="4"
            variant="outlined"
            density="comfortable"
            hide-details
            class="mb-4"
          ></v-textarea>

          <v-btn
            color="primary"
            @click="addRole"
            size="large"
            block
          >
            <v-icon start>mdi-plus</v-icon>
            Add Role to List
          </v-btn>
        </div>

        <!-- Added Roles List -->
        <v-divider v-if="roles.length > 0" class="my-6"></v-divider>

        <div v-if="roles.length > 0" class="roles-list">
          <h4 class="list-title">Roles to Map ({{ roles.length }})</h4>

          <div
            v-for="(role, index) in roles"
            :key="index"
            class="role-item"
          >
            <div class="role-content">
              <div class="role-title">{{ role.title }}</div>
              <div class="role-description">{{ role.description }}</div>
            </div>
            <v-btn
              icon="mdi-delete"
              size="small"
              color="error"
              variant="text"
              @click="removeRole(index)"
            ></v-btn>
          </div>
        </div>
      </div>
    </div>

    <!-- Action Buttons -->
    <div class="action-buttons">
      <v-btn
        color="primary"
        size="x-large"
        @click="startMapping"
        :disabled="roles.length === 0 || loading"
        :loading="loading"
        block
      >
        <v-icon start size="24">mdi-robot</v-icon>
        Start AI Mapping ({{ roles.length }} {{ roles.length === 1 ? 'Role' : 'Roles' }})
      </v-btn>
    </div>

    <!-- Dialogs -->
    <v-dialog v-model="showProgressDialog" persistent max-width="500">
      <v-card color="white">
        <v-card-title class="text-h6 bg-white">AI Mapping in Progress</v-card-title>
        <v-card-text class="bg-white">
          <v-progress-linear
            indeterminate
            color="primary"
            class="mb-4"
          ></v-progress-linear>
          <p>Analyzing {{ roles.length }} roles using AI...</p>
          <p class="text-caption">This may take a few moments.</p>
        </v-card-text>
      </v-card>
    </v-dialog>

    <v-dialog v-model="showErrorDialog" max-width="500">
      <v-card color="white">
        <v-card-title class="text-error bg-white">Error</v-card-title>
        <v-card-text class="bg-white">
          <p>{{ errorMessage }}</p>
        </v-card-text>
        <v-card-actions class="bg-white">
          <v-spacer></v-spacer>
          <v-btn color="primary" @click="showErrorDialog = false">OK</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import axios from 'axios'

const props = defineProps({
  organizationId: {
    type: Number,
    required: true
  }
})

const emit = defineEmits(['cancel', 'mapping-complete'])

// Reactive state
const tab = ref('file')
const loading = ref(false)
const showProgressDialog = ref(false)
const showErrorDialog = ref(false)
const errorMessage = ref('')
const fileProcessing = ref(false)
const uploadedFile = ref(null)
const currentRole = ref({
  title: '',
  description: ''
})
const roles = ref([])

// Methods
const addRole = () => {
  if (!currentRole.value.title || !currentRole.value.title.trim()) {
    errorMessage.value = 'Please provide a role title'
    showErrorDialog.value = true
    return
  }

  if (!currentRole.value.description || !currentRole.value.description.trim()) {
    errorMessage.value = 'Please provide a role description'
    showErrorDialog.value = true
    return
  }

  // Add role with empty arrays for responsibilities and skills (AI will infer them)
  roles.value.push({
    title: currentRole.value.title.trim(),
    description: currentRole.value.description.trim(),
    responsibilities: [],
    skills: []
  })

  // Reset form
  currentRole.value = {
    title: '',
    description: ''
  }
}

const removeRole = (index) => {
  roles.value.splice(index, 1)
}

const handleDocumentUpload = async (event) => {
  const files = event.target?.files || event
  const file = files?.[0]

  if (!file) return

  // Check file type
  const allowedTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain'
  ]

  if (!allowedTypes.includes(file.type) && !file.name.match(/\.(pdf|doc|docx|txt)$/i)) {
    errorMessage.value = 'Unsupported file type. Please upload PDF, DOC, DOCX, or TXT files.'
    showErrorDialog.value = true
    return
  }

  fileProcessing.value = true

  try {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('organization_id', props.organizationId)

    const response = await axios.post('/api/phase1/extract-roles-from-document', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    if (response.data.success) {
      roles.value = response.data.roles
    } else {
      errorMessage.value = 'Failed to extract roles from document: ' + (response.data.error || 'Unknown error')
      showErrorDialog.value = true
    }
  } catch (error) {
    console.error('Document upload error:', error)
    errorMessage.value = 'Error processing document: ' + (error.response?.data?.error || error.message)
    showErrorDialog.value = true
  } finally {
    fileProcessing.value = false
  }
}

const startMapping = async () => {
  loading.value = true
  showProgressDialog.value = true

  try {
    const response = await axios.post('/api/phase1/map-roles', {
      organization_id: props.organizationId,
      roles: roles.value
    })

    if (response.data.success) {
      emit('mapping-complete', response.data.data)
    } else {
      errorMessage.value = 'Mapping failed: ' + response.data.error
      showErrorDialog.value = true
    }
  } catch (error) {
    errorMessage.value = 'Error during mapping: ' + (error.response?.data?.error || error.message)
    showErrorDialog.value = true
  } finally {
    loading.value = false
    showProgressDialog.value = false
  }
}
</script>

<style scoped>
.role-mapper-container {
  width: 100%;
}

.tabs-content {
  min-height: 400px;
}

.tab-panel {
  width: 100%;
}

/* ========================================
   FILE UPLOAD TAB
   ======================================== */
.upload-dropzone {
  position: relative;
  min-height: 350px;
  border: 3px dashed #409EFF;
  border-radius: 12px;
  background: white;
  padding: 40px;
  text-align: center;
  transition: all 0.3s ease;
}

.upload-dropzone:hover {
  border-color: #66b1ff;
  background: #f0f9ff;
}

.upload-dropzone.is-processing {
  border-color: #E6A23C;
  background: #fef8f0;
}

.upload-dropzone.has-file {
  border-color: #67C23A;
  background: #f0f9ff;
}

.upload-dropzone .v-file-input {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0.01;
  cursor: pointer;
  z-index: 10;
}

.upload-instructions,
.processing-state,
.success-state {
  pointer-events: none;
  position: relative;
  z-index: 1;
}

.upload-instructions h3,
.processing-state h3,
.success-state h3 {
  margin: 16px 0 8px;
  font-size: 20px;
  color: #303133;
}

.upload-instructions p,
.processing-state p,
.success-state p {
  margin: 4px 0;
  color: #606266;
  font-size: 14px;
}

/* ========================================
   MANUAL ENTRY TAB
   ======================================== */
.manual-entry-form {
  background: white;
  padding: 24px;
  border-radius: 8px;
  border: 2px solid #e4e7ed;
}

.roles-list {
  margin-top: 24px;
}

.list-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 16px;
}

.role-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 16px;
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  margin-bottom: 12px;
  transition: all 0.3s ease;
}

.role-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border-color: #409EFF;
}

.role-content {
  flex: 1;
}

.role-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 4px;
}

.role-description {
  font-size: 14px;
  color: #606266;
  line-height: 1.5;
}

/* ========================================
   ACTION BUTTONS
   ======================================== */
.action-buttons {
  margin-top: 32px;
  padding-top: 24px;
  border-top: 2px solid #e4e7ed;
}

/* Ensure divider is visible */
.v-divider {
  border-color: #e0e0e0;
  margin: 24px 0;
}
</style>
