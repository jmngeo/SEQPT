<template>
  <el-card class="pmt-context-form">
    <template #header>
      <div class="card-header">
        <span>Organization SE Practices</span>
        <el-tag type="warning">Required for Selected Strategies</el-tag>
      </div>
    </template>

    <!-- Introduction Section - Styled nicely -->
    <div class="intro-section">
      <div class="intro-icon">
        <el-icon :size="32" color="#409EFF"><InfoFilled /></el-icon>
      </div>
      <div class="intro-content">
        <h4 class="intro-title">Share Your Organization's SE Practices</h4>
        <p class="intro-description">
          To personalize learning objectives for your organization, we need to understand the
          <strong>Systems Engineering practices</strong> currently in use. This includes:
        </p>
        <div class="practice-types">
          <div class="practice-type">
            <span class="practice-label">Processes:</span>
            <span class="practice-desc">Development lifecycles, workflows, standards (e.g., V-model, ISO 26262, Agile)</span>
          </div>
          <div class="practice-type">
            <span class="practice-label">Methods:</span>
            <span class="practice-desc">Technical approaches used in engineering (e.g., SysML modeling, FMEA, trade-off analysis)</span>
          </div>
          <div class="practice-type">
            <span class="practice-label">Tools:</span>
            <span class="practice-desc">Software platforms supporting your work (e.g., DOORS, JIRA, Cameo, Git)</span>
          </div>
        </div>
        <p class="intro-hint">
          You can upload existing documentation or enter the information manually below.
        </p>
      </div>
    </div>

    <!-- Reference Examples Section -->
    <el-collapse v-model="activeCollapse" style="margin-bottom: 24px;">
      <el-collapse-item name="examples">
        <template #title>
          <el-icon><DocumentCopy /></el-icon>
          <span style="margin-left: 8px;">View Example PMT Documents</span>
          <el-tag size="small" type="info" style="margin-left: 12px;">Helpful References</el-tag>
        </template>

        <div class="examples-section">
          <p class="examples-description">
            Not sure what to upload? Download these example documents to understand what Process, Method, and Tool documentation looks like:
          </p>

          <div v-if="loadingExamples" class="loading-examples">
            <el-icon class="is-loading"><Loading /></el-icon>
            <span>Loading examples...</span>
          </div>

          <div v-else-if="referenceExamples.length > 0" class="examples-grid">
            <div
              v-for="example in referenceExamples"
              :key="example.filename"
              class="example-card"
              :class="`type-${example.type}`"
            >
              <div class="example-header">
                <el-tag :type="getTypeTagType(example.type)" size="small">
                  {{ example.type.toUpperCase() }}
                </el-tag>
              </div>
              <div class="example-name">{{ example.name }}</div>
              <div class="example-actions">
                <el-button
                  size="small"
                  type="primary"
                  text
                  @click="downloadExample(example.filename)"
                >
                  <el-icon><Download /></el-icon>
                  Download
                </el-button>
              </div>
            </div>
          </div>

          <el-empty v-else description="No example files available" :image-size="60" />
        </div>
      </el-collapse-item>
    </el-collapse>

    <!-- Input Mode Tabs -->
    <el-tabs v-model="inputMode" type="border-card">
      <!-- File Upload Tab -->
      <el-tab-pane label="Upload Documents" name="upload">
        <template #label>
          <span><el-icon><Upload /></el-icon> Upload Documents</span>
        </template>

        <div class="upload-section">
          <p class="upload-description">
            Upload your organization's Process, Method, or Tool documents.
            The AI will automatically extract relevant PMT information and update the form.
          </p>

          <el-upload
            ref="uploadRef"
            class="upload-area"
            drag
            :auto-upload="false"
            :on-change="handleFileSelect"
            :limit="5"
            accept=".pdf,.doc,.docx,.txt"
            :file-list="uploadedFiles"
          >
            <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
            <div class="el-upload__text">
              Drop files here or <em>click to upload</em>
            </div>
            <template #tip>
              <div class="el-upload__tip">
                Supported formats: PDF, DOC, DOCX, TXT (max 5 files)
              </div>
            </template>
          </el-upload>

          <!-- Uploaded Files List -->
          <div v-if="uploadedFiles.length > 0" class="uploaded-files">
            <h4>Files to Process ({{ uploadedFiles.length }})</h4>
            <div
              v-for="(file, index) in uploadedFiles"
              :key="index"
              class="file-item"
            >
              <el-icon><Document /></el-icon>
              <span class="file-name">{{ file.name }}</span>
              <span class="file-size">{{ formatFileSize(file.size) }}</span>
              <el-button
                type="danger"
                text
                size="small"
                @click="removeFile(index)"
                :disabled="isExtracting"
              >
                <el-icon><Delete /></el-icon>
              </el-button>
            </div>
          </div>

          <!-- Extract Button -->
          <el-button
            v-if="uploadedFiles.length > 0 && !isExtracting && !extractionComplete"
            type="primary"
            size="large"
            style="margin-top: 16px; width: 100%;"
            @click="extractFromDocuments"
          >
            <el-icon><MagicStick /></el-icon>
            Extract PMT from {{ uploadedFiles.length }} Document(s)
          </el-button>

          <!-- Extraction Progress -->
          <div v-if="isExtracting" class="extraction-progress">
            <el-progress
              :percentage="extractionProgress"
              :format="formatProgress"
              :stroke-width="20"
              status="success"
            />
            <p class="progress-text">
              Processing document {{ currentDocIndex + 1 }} of {{ uploadedFiles.length }}...
              <br/>
              <span class="progress-filename">{{ currentDocName }}</span>
            </p>
          </div>

          <!-- Extraction Complete Summary -->
          <div v-if="extractionComplete && !isExtracting" class="extraction-complete">
            <el-result
              icon="success"
              title="SE Practices Saved"
              :sub-title="`Extracted and saved PMT context from ${uploadedFiles.length} document(s)`"
            >
              <template #extra>
                <el-button type="primary" @click="switchToManualTab">
                  Review Extracted Data
                </el-button>
                <el-button @click="resetExtraction">
                  Upload Different Files
                </el-button>
              </template>
            </el-result>

            <!-- Summary of what was extracted -->
            <div class="extraction-summary">
              <h4>Extraction Summary</h4>
              <div class="summary-grid">
                <div class="summary-item">
                  <el-tag type="primary" size="large">PROCESSES</el-tag>
                  <p>{{ extractionSummary.processCount }} items extracted</p>
                </div>
                <div class="summary-item">
                  <el-tag type="success" size="large">METHODS</el-tag>
                  <p>{{ extractionSummary.methodCount }} items extracted</p>
                </div>
                <div class="summary-item">
                  <el-tag type="warning" size="large">TOOLS</el-tag>
                  <p>{{ extractionSummary.toolCount }} items extracted</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- Manual Entry Tab -->
      <el-tab-pane label="Manual Entry" name="manual">
        <template #label>
          <span><el-icon><Edit /></el-icon> Manual Entry</span>
        </template>

        <el-form
          ref="formRef"
          :model="formData"
          label-position="top"
        >
          <el-form-item label="Processes">
            <el-input
              v-model="formData.processes"
              type="textarea"
              :rows="4"
              placeholder="e.g., ISO 26262 for automotive safety, V-model for development, Agile development process, Requirements approval workflow"
            />
            <span class="help-text">
              Organizational workflows, procedures, standards followed, development lifecycle, approval gates
            </span>
          </el-form-item>

          <el-form-item label="Methods">
            <el-input
              v-model="formData.methods"
              type="textarea"
              :rows="4"
              placeholder="e.g., SysML modeling, trade-off analysis, FMEA, design reviews, requirements traceability"
            />
            <span class="help-text">
              Technical techniques and approaches: modeling methods, analysis techniques, review processes
            </span>
          </el-form-item>

          <el-form-item label="Tools">
            <el-input
              v-model="formData.tools"
              type="textarea"
              :rows="4"
              placeholder="e.g., DOORS for requirements, JIRA for project management, Enterprise Architect for SysML, Git for version control"
            />
            <span class="help-text">
              Software and platforms: requirements tools, project management, modeling tools, version control
            </span>
          </el-form-item>
        </el-form>
      </el-tab-pane>
    </el-tabs>

    <!-- Save Button -->
    <div class="form-actions">
      <el-button type="primary" size="large" @click="handleSave" :loading="isSaving">
        <el-icon><Check /></el-icon>
        Save SE Practices
      </el-button>

      <el-tag v-if="hasExistingContext" type="success" style="margin-left: 12px;">
        <el-icon><CircleCheck /></el-icon>
        SE Practices Saved
      </el-tag>
    </div>
  </el-card>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Upload, UploadFilled, Download, Document, Delete, Edit,
  MagicStick, Check, CircleCheck, DocumentCopy, Loading, InfoFilled
} from '@element-plus/icons-vue'
import { phase2Task3Api } from '@/api/phase2'

const props = defineProps({
  organizationId: {
    type: Number,
    required: true
  },
  existingContext: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['saved', 'cancelled'])

// Refs
const formRef = ref(null)
const uploadRef = ref(null)

// State
const inputMode = ref('upload')
const activeCollapse = ref([])
const isSaving = ref(false)
const isExtracting = ref(false)
const loadingExamples = ref(false)
const extractionComplete = ref(false)
const extractionProgress = ref(0)
const currentDocIndex = ref(0)
const currentDocName = ref('')

// Form data
const formData = ref({
  processes: '',
  methods: '',
  tools: ''
})

// Upload state
const uploadedFiles = ref([])

// Extraction summary
const extractionSummary = ref({
  processCount: 0,
  methodCount: 0,
  toolCount: 0
})

// Reference examples
const referenceExamples = ref([])

// Computed
const hasExistingContext = computed(() => {
  return props.existingContext && (
    props.existingContext.processes ||
    props.existingContext.methods ||
    props.existingContext.tools
  )
})

// Methods
const loadExistingContext = () => {
  if (props.existingContext) {
    formData.value = {
      processes: props.existingContext.processes || '',
      methods: props.existingContext.methods || '',
      tools: props.existingContext.tools || ''
    }
    console.log('[PMTContextForm] Loaded existing context')
  }
}

const loadReferenceExamples = async () => {
  loadingExamples.value = true
  try {
    const response = await phase2Task3Api.getPMTReferenceExamples()
    if (response.success) {
      referenceExamples.value = response.examples
    }
  } catch (error) {
    console.error('[PMTContextForm] Failed to load examples:', error)
  } finally {
    loadingExamples.value = false
  }
}

const downloadExample = (filename) => {
  const url = phase2Task3Api.getPMTExampleDownloadUrl(filename)
  window.open(url, '_blank')
}

const getTypeTagType = (type) => {
  switch (type) {
    case 'process': return 'primary'
    case 'method': return 'success'
    case 'tool': return 'warning'
    default: return 'info'
  }
}

const formatFileSize = (bytes) => {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
}

const formatProgress = (percentage) => {
  return `${percentage}%`
}

const handleFileSelect = (file) => {
  // Element Plus upload component adds raw property
  if (file.raw) {
    uploadedFiles.value.push(file.raw)
  }
  // Reset extraction state when new files added
  extractionComplete.value = false
}

const removeFile = (index) => {
  uploadedFiles.value.splice(index, 1)
  extractionComplete.value = false
}

const resetExtraction = () => {
  uploadedFiles.value = []
  extractionComplete.value = false
  extractionProgress.value = 0
  extractionSummary.value = { processCount: 0, methodCount: 0, toolCount: 0 }
}

const switchToManualTab = () => {
  inputMode.value = 'manual'
}

const extractFromDocuments = async () => {
  if (uploadedFiles.value.length === 0) return

  isExtracting.value = true
  extractionProgress.value = 0
  extractionComplete.value = false

  // Clear previous PMT data - overwrite mode
  formData.value = {
    processes: '',
    methods: '',
    tools: ''
  }

  // Reset summary
  extractionSummary.value = { processCount: 0, methodCount: 0, toolCount: 0 }

  // Collect all extracted text
  const allProcesses = []
  const allMethods = []
  const allTools = []

  try {
    // Process each file sequentially
    for (let i = 0; i < uploadedFiles.value.length; i++) {
      const file = uploadedFiles.value[i]
      currentDocIndex.value = i
      currentDocName.value = file.name

      try {
        const result = await phase2Task3Api.extractPMTFromDocument(props.organizationId, file)

        if (result.success && result.pmt_data) {
          const suggested = result.pmt_data.suggested_text || {}

          // Collect extracted text
          if (suggested.processes) {
            allProcesses.push(suggested.processes)
          }
          if (suggested.methods) {
            allMethods.push(suggested.methods)
          }
          if (suggested.tools) {
            allTools.push(suggested.tools)
          }

          // Update summary counts
          extractionSummary.value.processCount += result.pmt_data.processes?.length || 0
          extractionSummary.value.methodCount += result.pmt_data.methods?.length || 0
          extractionSummary.value.toolCount += result.pmt_data.tools?.length || 0
        }
      } catch (error) {
        console.error(`[PMTContextForm] Error processing ${file.name}:`, error)
        // Continue with other files
      }

      // Update progress
      extractionProgress.value = Math.round(((i + 1) / uploadedFiles.value.length) * 100)
    }

    // Combine all extracted data (overwrites previous)
    formData.value.processes = allProcesses.join('\n\n')
    formData.value.methods = allMethods.join('\n\n')
    formData.value.tools = allTools.join('\n\n')

    extractionComplete.value = true

    // Auto-save after successful extraction - no need for user to click Save button
    if (formData.value.processes || formData.value.methods || formData.value.tools) {
      try {
        const response = await phase2Task3Api.savePMTContext(props.organizationId, formData.value)
        console.log('[PMTContextForm] PMT context auto-saved after extraction:', response)
        ElMessage.success(`Extracted and saved SE Practices from ${uploadedFiles.value.length} document(s)`)
        emit('saved', response.data || formData.value)
      } catch (saveError) {
        console.error('[PMTContextForm] Auto-save after extraction failed:', saveError)
        ElMessage.warning('Extracted PMT data but failed to save. Please review and save manually.')
      }
    } else {
      ElMessage.warning('No PMT information could be extracted from the documents')
    }

  } catch (error) {
    console.error('[PMTContextForm] Extraction error:', error)
    ElMessage.error('Failed to extract PMT information')
  } finally {
    isExtracting.value = false
  }
}

const handleSave = async () => {
  try {
    isSaving.value = true

    const response = await phase2Task3Api.savePMTContext(props.organizationId, formData.value)

    console.log('[PMTContextForm] PMT context saved:', response)
    ElMessage.success('PMT context saved successfully. Learning objectives will be customized with this context.')
    emit('saved', response.data || formData.value)
  } catch (error) {
    console.error('[PMTContextForm] Error saving PMT context:', error)
    ElMessage.error('Failed to save PMT context')
  } finally {
    isSaving.value = false
  }
}

// Watch for existing context changes
watch(() => props.existingContext, () => {
  loadExistingContext()
}, { deep: true })

// Lifecycle
onMounted(() => {
  loadExistingContext()
  loadReferenceExamples()
})
</script>

<style scoped>
.pmt-context-form {
  margin-bottom: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.help-text {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  display: block;
  margin-top: 4px;
}

/* Introduction Section - Enhanced styling */
.intro-section {
  display: flex;
  gap: 20px;
  padding: 20px 24px;
  background: linear-gradient(135deg, #f0f9ff 0%, #e6f4ff 100%);
  border: 1px solid #b3d9ff;
  border-left: 4px solid #409EFF;
  border-radius: 8px;
  margin-bottom: 24px;
}

.intro-icon {
  flex-shrink: 0;
  display: flex;
  align-items: flex-start;
  padding-top: 4px;
}

.intro-content {
  flex: 1;
}

.intro-title {
  margin: 0 0 12px 0;
  font-size: 16px;
  font-weight: 600;
  color: #1E293B;
}

.intro-description {
  margin: 0 0 16px 0;
  font-size: 14px;
  color: #475569;
  line-height: 1.6;
}

.practice-types {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 16px;
  padding: 14px 16px;
  background: white;
  border-radius: 6px;
  border: 1px solid #E2E8F0;
}

.practice-type {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 13px;
  line-height: 1.5;
}

.practice-label {
  font-weight: 600;
  color: #303133;
  min-width: 80px;
  flex-shrink: 0;
}

.practice-desc {
  color: #606266;
}

.intro-hint {
  margin: 0;
  font-size: 13px;
  color: #909399;
  font-style: italic;
}

/* Examples Section */
.examples-section {
  padding: 8px 0;
}

.examples-description {
  font-size: 14px;
  color: var(--el-text-color-secondary);
  margin-bottom: 16px;
}

.loading-examples {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--el-text-color-secondary);
  padding: 16px;
}

.examples-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
}

.example-card {
  border: 1px solid var(--el-border-color);
  border-radius: 8px;
  padding: 12px;
  transition: all 0.3s ease;
}

.example-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.example-card.type-process {
  border-left: 3px solid var(--el-color-primary);
}

.example-card.type-method {
  border-left: 3px solid var(--el-color-success);
}

.example-card.type-tool {
  border-left: 3px solid var(--el-color-warning);
}

.example-header {
  margin-bottom: 8px;
}

.example-name {
  font-weight: 500;
  font-size: 14px;
  margin-bottom: 8px;
}

.example-actions {
  text-align: right;
}

/* Upload Section */
.upload-section {
  padding: 8px 0;
}

.upload-description {
  font-size: 14px;
  color: var(--el-text-color-secondary);
  margin-bottom: 16px;
}

.upload-area {
  margin-bottom: 16px;
}

.uploaded-files {
  margin-top: 16px;
  padding: 16px;
  background: var(--el-fill-color-light);
  border-radius: 8px;
}

.uploaded-files h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  font-weight: 600;
}

.file-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px;
  background: white;
  border-radius: 4px;
  margin-bottom: 8px;
}

.file-item:last-child {
  margin-bottom: 0;
}

.file-name {
  flex: 1;
  font-size: 14px;
}

.file-size {
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

/* Extraction Progress */
.extraction-progress {
  margin-top: 24px;
  padding: 24px;
  background: var(--el-fill-color-light);
  border-radius: 8px;
  text-align: center;
}

.progress-text {
  margin-top: 16px;
  color: var(--el-text-color-regular);
}

.progress-filename {
  font-weight: 500;
  color: var(--el-color-primary);
}

/* Extraction Complete */
.extraction-complete {
  margin-top: 24px;
}

.extraction-summary {
  margin-top: 24px;
  padding: 16px;
  background: var(--el-fill-color-light);
  border-radius: 8px;
}

.extraction-summary h4 {
  margin: 0 0 16px 0;
  font-size: 14px;
  font-weight: 600;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.summary-item {
  text-align: center;
  padding: 12px;
  background: white;
  border-radius: 8px;
}

.summary-item p {
  margin: 8px 0 0 0;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}

/* Form Actions */
.form-actions {
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid var(--el-border-color);
  display: flex;
  align-items: center;
}
</style>
