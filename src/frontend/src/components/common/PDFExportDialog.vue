<template>
  <el-dialog
    v-model="visible"
    title="Export to PDF"
    width="50%"
    :before-close="handleClose"
    class="pdf-export-dialog"
  >
    <div class="export-content">
      <div class="export-preview">
        <div class="preview-header">
          <h3>{{ exportData.title || 'Document' }}</h3>
          <p v-if="exportData.description">{{ exportData.description }}</p>
        </div>

        <div class="preview-stats" v-if="showStats">
          <div class="stat-item">
            <i class="el-icon-document"></i>
            <span>{{ estimatedPages }} pages</span>
          </div>
          <div class="stat-item">
            <i class="el-icon-time"></i>
            <span>{{ estimatedSize }}</span>
          </div>
        </div>
      </div>

      <el-form :model="exportOptions" label-width="140px" class="export-form">
        <el-form-item label="Export Type">
          <el-radio-group v-model="exportOptions.type">
            <el-radio
              v-for="type in availableTypes"
              :key="type.value"
              :label="type.value"
            >
              {{ type.label }}
            </el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="Include">
          <el-checkbox-group v-model="exportOptions.include">
            <el-checkbox
              v-for="option in includeOptions"
              :key="option.value"
              :label="option.value"
              :disabled="option.disabled"
            >
              {{ option.label }}
            </el-checkbox>
          </el-checkbox-group>
        </el-form-item>

        <el-form-item label="Page Format">
          <el-select v-model="exportOptions.format" style="width: 150px;">
            <el-option label="A4 Portrait" value="a4-portrait"></el-option>
            <el-option label="A4 Landscape" value="a4-landscape"></el-option>
            <el-option label="Letter Portrait" value="letter-portrait"></el-option>
            <el-option label="Letter Landscape" value="letter-landscape"></el-option>
          </el-select>
        </el-form-item>

        <el-form-item label="Quality" v-if="exportOptions.include.includes('charts')">
          <el-slider
            v-model="exportOptions.quality"
            :min="1"
            :max="3"
            :step="1"
            :marks="{ 1: 'Low', 2: 'Medium', 3: 'High' }"
            style="width: 200px;"
          ></el-slider>
        </el-form-item>

        <el-form-item label="Date Range" v-if="supportsDateRange">
          <el-date-picker
            v-model="exportOptions.dateRange"
            type="datetimerange"
            range-separator="to"
            start-placeholder="Start date"
            end-placeholder="End date"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          ></el-date-picker>
        </el-form-item>

        <el-form-item label="Custom Title">
          <el-input
            v-model="exportOptions.customTitle"
            placeholder="Enter custom title (optional)"
          ></el-input>
        </el-form-item>

        <el-form-item label="Watermark" v-if="showAdvanced">
          <el-switch v-model="exportOptions.watermark"></el-switch>
          <span class="form-helper">Add "CONFIDENTIAL" watermark</span>
        </el-form-item>

        <el-form-item label="Password Protection" v-if="showAdvanced">
          <el-switch v-model="exportOptions.password" @change="onPasswordToggle"></el-switch>
          <el-input
            v-if="exportOptions.password"
            v-model="exportOptions.passwordValue"
            type="password"
            placeholder="Enter password"
            style="margin-top: 10px; width: 200px;"
            show-password
          ></el-input>
        </el-form-item>
      </el-form>

      <div class="advanced-options">
        <el-button type="text" @click="showAdvanced = !showAdvanced">
          <i :class="showAdvanced ? 'el-icon-arrow-up' : 'el-icon-arrow-down'"></i>
          {{ showAdvanced ? 'Hide' : 'Show' }} Advanced Options
        </el-button>
      </div>
    </div>

    <template #footer>
      <div class="dialog-footer">
        <div class="footer-info">
          <el-tooltip content="Preview before export" placement="top">
            <el-button @click="previewPDF" :loading="previewing" icon="el-icon-view">
              Preview
            </el-button>
          </el-tooltip>
        </div>
        <div class="footer-actions">
          <el-button @click="handleClose">Cancel</el-button>
          <el-button type="primary" @click="exportPDF" :loading="exporting">
            <i class="el-icon-download"></i>
            Export PDF
          </el-button>
        </div>
      </div>
    </template>

    <!-- Preview Dialog -->
    <el-dialog
      v-model="previewVisible"
      title="PDF Preview"
      width="70%"
      class="preview-dialog"
    >
      <div class="pdf-preview">
        <div v-if="previewURL" class="preview-container">
          <iframe
            :src="previewURL"
            width="100%"
            height="600px"
            frameborder="0"
          ></iframe>
        </div>
        <div v-else class="preview-loading">
          <el-icon class="is-loading"><i class="el-icon-loading"></i></el-icon>
          <p>Generating preview...</p>
        </div>
      </div>
      <template #footer>
        <el-button @click="previewVisible = false">Close Preview</el-button>
        <el-button type="primary" @click="exportFromPreview" :loading="exporting">
          Export This Version
        </el-button>
      </template>
    </el-dialog>
  </el-dialog>
</template>

<script>
import { ref, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { PDFExport } from '@/services/pdfExport'

export default {
  name: 'PDFExportDialog',
  emits: ['update:visible', 'export-complete'],
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    exportData: {
      type: Object,
      required: true
    },
    exportType: {
      type: String,
      default: 'assessment' // assessment, plan, analytics, rag, custom
    },
    options: {
      type: Object,
      default: () => ({})
    }
  },
  setup(props, { emit }) {
    // Reactive data
    const exporting = ref(false)
    const previewing = ref(false)
    const previewVisible = ref(false)
    const previewURL = ref('')
    const showAdvanced = ref(false)

    // Export options
    const exportOptions = ref({
      type: 'detailed',
      include: ['summary', 'details'],
      format: 'a4-portrait',
      quality: 2,
      dateRange: null,
      customTitle: '',
      watermark: false,
      password: false,
      passwordValue: ''
    })

    // Computed properties
    const availableTypes = computed(() => {
      const types = {
        assessment: [
          { value: 'summary', label: 'Summary Report' },
          { value: 'detailed', label: 'Detailed Report' },
          { value: 'certificate', label: 'Certificate' }
        ],
        plan: [
          { value: 'overview', label: 'Plan Overview' },
          { value: 'detailed', label: 'Detailed Plan' },
          { value: 'timeline', label: 'Timeline View' }
        ],
        analytics: [
          { value: 'executive', label: 'Executive Summary' },
          { value: 'detailed', label: 'Detailed Analytics' },
          { value: 'charts', label: 'Charts Only' }
        ],
        rag: [
          { value: 'objectives', label: 'Objectives Report' },
          { value: 'analysis', label: 'Quality Analysis' },
          { value: 'detailed', label: 'Detailed Report' }
        ]
      }
      return types[props.exportType] || types.assessment
    })

    const includeOptions = computed(() => {
      const options = {
        assessment: [
          { value: 'summary', label: 'Summary Information' },
          { value: 'details', label: 'Detailed Results' },
          { value: 'charts', label: 'Score Charts' },
          { value: 'competencies', label: 'Competency Breakdown' },
          { value: 'recommendations', label: 'Recommendations' }
        ],
        plan: [
          { value: 'overview', label: 'Plan Overview' },
          { value: 'objectives', label: 'Learning Objectives' },
          { value: 'modules', label: 'Training Modules' },
          { value: 'timeline', label: 'Timeline' },
          { value: 'progress', label: 'Progress Tracking' }
        ],
        analytics: [
          { value: 'overview', label: 'Overview Metrics' },
          { value: 'charts', label: 'Charts & Graphs' },
          { value: 'trends', label: 'Trend Analysis' },
          { value: 'performers', label: 'Top Performers' },
          { value: 'insights', label: 'Key Insights' }
        ],
        rag: [
          { value: 'context', label: 'Generation Context' },
          { value: 'objectives', label: 'Generated Objectives' },
          { value: 'analysis', label: 'SMART Analysis' },
          { value: 'validation', label: 'Validation Results' },
          { value: 'sources', label: 'RAG Sources' }
        ]
      }
      return options[props.exportType] || options.assessment
    })

    const supportsDateRange = computed(() => {
      return ['analytics', 'plan'].includes(props.exportType)
    })

    const showStats = computed(() => {
      return props.exportData && Object.keys(props.exportData).length > 0
    })

    const estimatedPages = computed(() => {
      let pages = 1
      if (exportOptions.value.include.includes('details')) pages += 2
      if (exportOptions.value.include.includes('charts')) pages += 1
      if (exportOptions.value.include.includes('objectives')) pages += Math.ceil((props.exportData.objectives?.length || 0) / 3)
      return pages
    })

    const estimatedSize = computed(() => {
      const baseSize = 200 // KB
      const pageSize = exportOptions.value.quality * 50
      const totalSize = baseSize + (estimatedPages.value * pageSize)
      return totalSize > 1024 ? `${(totalSize / 1024).toFixed(1)} MB` : `${totalSize} KB`
    })

    // Methods
    const handleClose = () => {
      emit('update:visible', false)
      resetOptions()
    }

    const resetOptions = () => {
      exportOptions.value = {
        type: 'detailed',
        include: ['summary', 'details'],
        format: 'a4-portrait',
        quality: 2,
        dateRange: null,
        customTitle: '',
        watermark: false,
        password: false,
        passwordValue: ''
      }
      showAdvanced.value = false
      previewURL.value = ''
      previewVisible.value = false
    }

    const onPasswordToggle = (value) => {
      if (!value) {
        exportOptions.value.passwordValue = ''
      }
    }

    const previewPDF = async () => {
      previewing.value = true
      try {
        const exporter = await generatePDF(true)
        previewURL.value = exporter.getDataURL()
        previewVisible.value = true
      } catch (error) {
        console.error('Error generating preview:', error)
        ElMessage.error('Failed to generate preview')
      } finally {
        previewing.value = false
      }
    }

    const exportPDF = async () => {
      await performExport()
    }

    const exportFromPreview = async () => {
      previewVisible.value = false
      await performExport()
    }

    const performExport = async () => {
      exporting.value = true
      try {
        await generatePDF(false)
        ElMessage.success('PDF exported successfully')
        emit('export-complete', exportOptions.value)
        handleClose()
      } catch (error) {
        console.error('Error exporting PDF:', error)
        ElMessage.error('Failed to export PDF')
      } finally {
        exporting.value = false
      }
    }

    const generatePDF = async (isPreview = false) => {
      const options = {
        ...exportOptions.value,
        filename: generateFilename(),
        preview: isPreview
      }

      // Route to appropriate export function based on type
      switch (props.exportType) {
        case 'assessment':
          return await PDFExport.exportAssessment(props.exportData, options)
        case 'plan':
          return await PDFExport.exportQualificationPlan(props.exportData, options)
        case 'analytics':
          return await PDFExport.exportAnalytics(props.exportData, options)
        case 'rag':
          return await PDFExport.exportRAGObjectives(
            props.exportData.objectives,
            props.exportData.context,
            options
          )
        default:
          const exporter = PDFExport.createCustomReport(
            exportOptions.value.customTitle || props.exportData.title || 'SE-QPT Report'
          )

          // Add custom content based on exportData
          if (props.exportData.content) {
            exporter.addParagraph(props.exportData.content)
          }

          if (!isPreview) {
            exporter.save(options.filename)
          }

          return exporter
      }
    }

    const generateFilename = () => {
      const timestamp = new Date().toISOString().slice(0, 10)
      const type = props.exportType
      const title = exportOptions.value.customTitle || props.exportData.title || 'report'
      const safeName = title.toLowerCase().replace(/[^a-z0-9]/g, '-')
      return `se-qpt-${type}-${safeName}-${timestamp}.pdf`
    }

    // Watchers
    watch(() => props.visible, (newValue) => {
      if (newValue) {
        // Reset and initialize options when dialog opens
        resetOptions()
        if (props.options) {
          Object.assign(exportOptions.value, props.options)
        }
      }
    })

    return {
      exporting,
      previewing,
      previewVisible,
      previewURL,
      showAdvanced,
      exportOptions,
      availableTypes,
      includeOptions,
      supportsDateRange,
      showStats,
      estimatedPages,
      estimatedSize,
      handleClose,
      onPasswordToggle,
      previewPDF,
      exportPDF,
      exportFromPreview
    }
  }
}
</script>

<style scoped>
.pdf-export-dialog {
  max-width: 600px;
}

.export-content {
  padding: 10px 0;
}

.export-preview {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  border: 1px solid #e9ecef;
}

.preview-header h3 {
  margin: 0 0 8px 0;
  color: #2c3e50;
  font-size: 18px;
}

.preview-header p {
  margin: 0;
  color: #7f8c8d;
  font-size: 14px;
}

.preview-stats {
  display: flex;
  gap: 20px;
  margin-top: 15px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #667eea;
  font-size: 14px;
}

.stat-item i {
  font-size: 16px;
}

.export-form {
  margin: 20px 0;
}

.form-helper {
  margin-left: 10px;
  font-size: 12px;
  color: #7f8c8d;
}

.advanced-options {
  text-align: center;
  margin: 20px 0;
  padding-top: 15px;
  border-top: 1px solid #e9ecef;
}

.dialog-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer-actions {
  display: flex;
  gap: 10px;
}

/* Preview Dialog */
.preview-dialog {
  z-index: 3000;
}

.pdf-preview {
  min-height: 400px;
}

.preview-container {
  border: 1px solid #ddd;
  border-radius: 4px;
  overflow: hidden;
}

.preview-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 400px;
  color: #7f8c8d;
}

.preview-loading .el-icon {
  font-size: 32px;
  margin-bottom: 15px;
}

/* Responsive */
@media (max-width: 768px) {
  .pdf-export-dialog {
    width: 90% !important;
    max-width: none;
  }

  .preview-stats {
    flex-direction: column;
    gap: 10px;
  }

  .dialog-footer {
    flex-direction: column;
    gap: 15px;
  }

  .footer-actions {
    width: 100%;
    justify-content: center;
  }
}

/* Animation */
.export-content {
  animation: fadeInUp 0.3s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>