<template>
  <div class="admin-panel">
    <div class="page-header">
      <div class="header-content">
        <h1><i class="el-icon-setting"></i> SE-QPT Administration</h1>
        <p>Manage questionnaires, assessments, and system configuration</p>
      </div>
      <div class="header-stats">
        <div class="stat-card">
          <div class="stat-value">{{ totalQuestionnaires }}</div>
          <div class="stat-label">Questionnaires</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ totalQuestions }}</div>
          <div class="stat-label">Questions</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ totalUsers }}</div>
          <div class="stat-label">Users</div>
        </div>
      </div>
    </div>

    <el-tabs v-model="activeTab" type="border-card" class="admin-tabs">
      <!-- Questionnaire Management Tab -->
      <el-tab-pane label="Questionnaires" name="questionnaires">
        <div class="tab-content">
          <div class="content-header">
            <h2>Questionnaire Management</h2>
            <div class="header-actions">
              <el-button type="primary" @click="showCreateQuestionnaire">
                <i class="el-icon-plus"></i> Create Questionnaire
              </el-button>
              <el-button @click="loadQuestionnaires" :loading="loading.questionnaires">
                <i class="el-icon-refresh"></i> Refresh
              </el-button>
            </div>
          </div>

          <div class="filters-section">
            <el-row :gutter="20">
              <el-col :span="6">
                <el-select v-model="filters.phase" placeholder="Filter by Phase" clearable>
                  <el-option label="Phase 1" value="1"></el-option>
                  <el-option label="Phase 2" value="2"></el-option>
                  <el-option label="All Phases" value=""></el-option>
                </el-select>
              </el-col>
              <el-col :span="6">
                <el-select v-model="filters.status" placeholder="Filter by Status" clearable>
                  <el-option label="Active" value="active"></el-option>
                  <el-option label="Draft" value="draft"></el-option>
                  <el-option label="Archived" value="archived"></el-option>
                </el-select>
              </el-col>
              <el-col :span="12">
                <el-input
                  v-model="filters.search"
                  placeholder="Search questionnaires..."
                  prefix-icon="el-icon-search"
                  clearable
                ></el-input>
              </el-col>
            </el-row>
          </div>

          <el-table
            :data="filteredQuestionnaires"
            style="width: 100%"
            :loading="loading.questionnaires"
            stripe
          >
            <el-table-column prop="title" label="Title" width="300">
              <template #default="scope">
                <div class="questionnaire-title">
                  <strong>{{ scope.row.title }}</strong>
                  <p class="questionnaire-description">{{ scope.row.description }}</p>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="phase" label="Phase" width="80">
              <template #default="scope">
                <el-tag :type="getPhaseType(scope.row.phase)">
                  Phase {{ scope.row.phase }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="questionCount" label="Questions" width="100">
              <template #default="scope">
                <el-badge :value="scope.row.questionCount" class="question-badge">
                  <i class="el-icon-document"></i>
                </el-badge>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="Status" width="120">
              <template #default="scope">
                <el-tag :type="getStatusType(scope.row.status)">
                  {{ scope.row.status }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="Created" width="120">
              <template #default="scope">
                {{ formatDate(scope.row.createdAt) }}
              </template>
            </el-table-column>
            <el-table-column label="Actions" width="200">
              <template #default="scope">
                <el-button
                  type="text"
                  @click="editQuestionnaire(scope.row)"
                  size="small"
                >
                  <i class="el-icon-edit"></i> Edit
                </el-button>
                <el-button
                  type="text"
                  @click="manageQuestions(scope.row)"
                  size="small"
                >
                  <i class="el-icon-document"></i> Questions
                </el-button>
                <el-button
                  type="text"
                  @click="duplicateQuestionnaire(scope.row)"
                  size="small"
                >
                  <i class="el-icon-copy-document"></i> Duplicate
                </el-button>
                <el-button
                  type="text"
                  @click="deleteQuestionnaire(scope.row)"
                  size="small"
                  class="danger-button"
                >
                  <i class="el-icon-delete"></i> Delete
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>

      <!-- Question Management Tab -->
      <el-tab-pane label="Questions" name="questions">
        <div class="tab-content">
          <div class="content-header">
            <h2>Question Management</h2>
            <div class="header-actions">
              <el-button type="primary" @click="showCreateQuestion">
                <i class="el-icon-plus"></i> Create Question
              </el-button>
              <el-button @click="importQuestions">
                <i class="el-icon-upload"></i> Import Questions
              </el-button>
              <el-button @click="loadQuestions" :loading="loading.questions">
                <i class="el-icon-refresh"></i> Refresh
              </el-button>
            </div>
          </div>

          <div class="filters-section">
            <el-row :gutter="20">
              <el-col :span="6">
                <el-select v-model="questionFilters.type" placeholder="Question Type" clearable>
                  <el-option label="Multiple Choice" value="multiple_choice"></el-option>
                  <el-option label="Single Choice" value="single_choice"></el-option>
                  <el-option label="Rating Scale" value="rating"></el-option>
                  <el-option label="Text Input" value="text"></el-option>
                </el-select>
              </el-col>
              <el-col :span="6">
                <el-select v-model="questionFilters.competency" placeholder="Competency" clearable>
                  <el-option
                    v-for="comp in competencies"
                    :key="comp.id"
                    :label="comp.name"
                    :value="comp.id"
                  ></el-option>
                </el-select>
              </el-col>
              <el-col :span="12">
                <el-input
                  v-model="questionFilters.search"
                  placeholder="Search questions..."
                  prefix-icon="el-icon-search"
                  clearable
                ></el-input>
              </el-col>
            </el-row>
          </div>

          <el-table
            :data="filteredQuestions"
            style="width: 100%"
            :loading="loading.questions"
            stripe
            :row-class-name="getQuestionRowClass"
          >
            <el-table-column type="selection" width="55"></el-table-column>
            <el-table-column prop="text" label="Question" min-width="400">
              <template #default="scope">
                <div class="question-cell">
                  <div class="question-text">{{ scope.row.text }}</div>
                  <div class="question-meta">
                    <el-tag size="mini" :type="getQuestionTypeColor(scope.row.type)">
                      {{ scope.row.type }}
                    </el-tag>
                    <span class="competency-tag">{{ scope.row.competencyName }}</span>
                  </div>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="questionnaire" label="Questionnaire" width="200">
              <template #default="scope">
                <span v-if="scope.row.questionnaireName">{{ scope.row.questionnaireName }}</span>
                <el-tag v-else type="info" size="small">Unassigned</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="order" label="Order" width="80" sortable></el-table-column>
            <el-table-column label="Actions" width="180">
              <template #default="scope">
                <el-button
                  type="text"
                  @click="editQuestion(scope.row)"
                  size="small"
                >
                  <i class="el-icon-edit"></i> Edit
                </el-button>
                <el-button
                  type="text"
                  @click="previewQuestion(scope.row)"
                  size="small"
                >
                  <i class="el-icon-view"></i> Preview
                </el-button>
                <el-button
                  type="text"
                  @click="deleteQuestion(scope.row)"
                  size="small"
                  class="danger-button"
                >
                  <i class="el-icon-delete"></i> Delete
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <div v-if="selectedQuestions.length > 0" class="batch-actions">
            <el-button type="primary" @click="assignToQuestionnaire">
              Assign to Questionnaire ({{ selectedQuestions.length }})
            </el-button>
            <el-button @click="exportQuestions">Export Selected</el-button>
            <el-button type="danger" @click="deleteSelectedQuestions">
              Delete Selected
            </el-button>
          </div>
        </div>
      </el-tab-pane>

      <!-- Assessment Results Tab -->
      <el-tab-pane label="Assessment Results" name="results">
        <div class="tab-content">
          <div class="content-header">
            <h2>Assessment Results</h2>
            <div class="header-actions">
              <el-button @click="exportResults">
                <i class="el-icon-download"></i> Export Results
              </el-button>
              <el-button @click="loadResults" :loading="loading.results">
                <i class="el-icon-refresh"></i> Refresh
              </el-button>
            </div>
          </div>

          <div class="results-overview">
            <el-row :gutter="20">
              <el-col :span="6">
                <el-card class="overview-card">
                  <div class="overview-stat">
                    <div class="stat-icon">
                      <i class="el-icon-user"></i>
                    </div>
                    <div class="stat-content">
                      <div class="stat-number">{{ resultsStats.totalAssessments }}</div>
                      <div class="stat-label">Total Assessments</div>
                    </div>
                  </div>
                </el-card>
              </el-col>
              <el-col :span="6">
                <el-card class="overview-card">
                  <div class="overview-stat">
                    <div class="stat-icon">
                      <i class="el-icon-check"></i>
                    </div>
                    <div class="stat-content">
                      <div class="stat-number">{{ resultsStats.completedAssessments }}</div>
                      <div class="stat-label">Completed</div>
                    </div>
                  </div>
                </el-card>
              </el-col>
              <el-col :span="6">
                <el-card class="overview-card">
                  <div class="overview-stat">
                    <div class="stat-icon">
                      <i class="el-icon-star"></i>
                    </div>
                    <div class="stat-content">
                      <div class="stat-number">{{ resultsStats.averageScore }}%</div>
                      <div class="stat-label">Average Score</div>
                    </div>
                  </div>
                </el-card>
              </el-col>
              <el-col :span="6">
                <el-card class="overview-card">
                  <div class="overview-stat">
                    <div class="stat-icon">
                      <i class="el-icon-time"></i>
                    </div>
                    <div class="stat-content">
                      <div class="stat-number">{{ resultsStats.averageTime }}min</div>
                      <div class="stat-label">Avg Time</div>
                    </div>
                  </div>
                </el-card>
              </el-col>
            </el-row>
          </div>

          <el-table
            :data="assessmentResults"
            style="width: 100%"
            :loading="loading.results"
            stripe
          >
            <el-table-column prop="userName" label="User" width="200"></el-table-column>
            <el-table-column prop="questionnaireName" label="Questionnaire" width="250"></el-table-column>
            <el-table-column prop="score" label="Score" width="100">
              <template #default="scope">
                <el-progress
                  :percentage="scope.row.score"
                  :stroke-width="8"
                  :text-inside="true"
                ></el-progress>
              </template>
            </el-table-column>
            <el-table-column prop="completedAt" label="Completed" width="150">
              <template #default="scope">
                {{ formatDateTime(scope.row.completedAt) }}
              </template>
            </el-table-column>
            <el-table-column prop="duration" label="Duration" width="100">
              <template #default="scope">
                {{ scope.row.duration }}min
              </template>
            </el-table-column>
            <el-table-column label="Actions" width="150">
              <template #default="scope">
                <el-button
                  type="text"
                  @click="viewResultDetails(scope.row)"
                  size="small"
                >
                  <i class="el-icon-view"></i> Details
                </el-button>
                <el-button
                  type="text"
                  @click="exportSingleResult(scope.row)"
                  size="small"
                >
                  <i class="el-icon-download"></i> Export
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>

      <!-- System Configuration Tab -->
      <el-tab-pane label="Configuration" name="config">
        <div class="tab-content">
          <div class="content-header">
            <h2>System Configuration</h2>
            <div class="header-actions">
              <el-button type="primary" @click="saveConfiguration" :loading="saving">
                <i class="el-icon-check"></i> Save Changes
              </el-button>
              <el-button @click="resetConfiguration">
                <i class="el-icon-refresh"></i> Reset
              </el-button>
            </div>
          </div>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-card class="config-card">
                <template #header>
                  <span>Assessment Settings</span>
                </template>
                <el-form :model="configuration" label-width="200px">
                  <el-form-item label="Max Assessment Time">
                    <el-input-number
                      v-model="configuration.maxAssessmentTime"
                      :min="15"
                      :max="180"
                      suffix="minutes"
                    ></el-input-number>
                  </el-form-item>
                  <el-form-item label="Passing Score">
                    <el-slider
                      v-model="configuration.passingScore"
                      :min="50"
                      :max="100"
                      show-input
                      suffix="%"
                    ></el-slider>
                  </el-form-item>
                  <el-form-item label="Allow Retakes">
                    <el-switch v-model="configuration.allowRetakes"></el-switch>
                  </el-form-item>
                  <el-form-item label="Max Retake Attempts">
                    <el-input-number
                      v-model="configuration.maxRetakeAttempts"
                      :min="1"
                      :max="5"
                      :disabled="!configuration.allowRetakes"
                    ></el-input-number>
                  </el-form-item>
                  <el-form-item label="Show Results Immediately">
                    <el-switch v-model="configuration.showResultsImmediately"></el-switch>
                  </el-form-item>
                </el-form>
              </el-card>
            </el-col>
            <el-col :span="12">
              <el-card class="config-card">
                <template #header>
                  <span>RAG-LLM Settings</span>
                </template>
                <el-form :model="configuration.rag" label-width="200px">
                  <el-form-item label="Default Temperature">
                    <el-slider
                      v-model="configuration.rag.temperature"
                      :min="0"
                      :max="1"
                      :step="0.1"
                      show-input
                    ></el-slider>
                  </el-form-item>
                  <el-form-item label="Max Tokens">
                    <el-input-number
                      v-model="configuration.rag.maxTokens"
                      :min="100"
                      :max="2000"
                      :step="100"
                    ></el-input-number>
                  </el-form-item>
                  <el-form-item label="Quality Threshold">
                    <el-slider
                      v-model="configuration.rag.qualityThreshold"
                      :min="70"
                      :max="95"
                      :step="5"
                      show-input
                      suffix="%"
                    ></el-slider>
                  </el-form-item>
                  <el-form-item label="Auto-Validation">
                    <el-switch v-model="configuration.rag.autoValidation"></el-switch>
                  </el-form-item>
                </el-form>
              </el-card>
            </el-col>
          </el-row>

          <el-row :gutter="20" style="margin-top: 20px;">
            <el-col :span="12">
              <el-card class="config-card">
                <template #header>
                  <span>Email Notifications</span>
                </template>
                <el-form :model="configuration.notifications" label-width="200px">
                  <el-form-item label="Assessment Completion">
                    <el-switch v-model="configuration.notifications.assessmentCompletion"></el-switch>
                  </el-form-item>
                  <el-form-item label="Weekly Reports">
                    <el-switch v-model="configuration.notifications.weeklyReports"></el-switch>
                  </el-form-item>
                  <el-form-item label="System Updates">
                    <el-switch v-model="configuration.notifications.systemUpdates"></el-switch>
                  </el-form-item>
                </el-form>
              </el-card>
            </el-col>
            <el-col :span="12">
              <el-card class="config-card">
                <template #header>
                  <span>Data Retention</span>
                </template>
                <el-form :model="configuration.retention" label-width="200px">
                  <el-form-item label="Assessment Results">
                    <el-select v-model="configuration.retention.assessmentResults">
                      <el-option label="6 months" value="6m"></el-option>
                      <el-option label="1 year" value="1y"></el-option>
                      <el-option label="2 years" value="2y"></el-option>
                      <el-option label="Indefinite" value="indefinite"></el-option>
                    </el-select>
                  </el-form-item>
                  <el-form-item label="User Activity Logs">
                    <el-select v-model="configuration.retention.activityLogs">
                      <el-option label="30 days" value="30d"></el-option>
                      <el-option label="90 days" value="90d"></el-option>
                      <el-option label="6 months" value="6m"></el-option>
                      <el-option label="1 year" value="1y"></el-option>
                    </el-select>
                  </el-form-item>
                  <el-form-item label="Auto-cleanup">
                    <el-switch v-model="configuration.retention.autoCleanup"></el-switch>
                  </el-form-item>
                </el-form>
              </el-card>
            </el-col>
          </el-row>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- Questionnaire Dialog -->
    <el-dialog
      v-model="questionnaireDialogVisible"
      :title="editingQuestionnaire.id ? 'Edit Questionnaire' : 'Create Questionnaire'"
      width="60%"
      :before-close="closeQuestionnaireDialog"
    >
      <el-form
        :model="editingQuestionnaire"
        :rules="questionnaireRules"
        ref="questionnaireForm"
        label-width="120px"
      >
        <el-form-item label="Title" prop="title">
          <el-input v-model="editingQuestionnaire.title" placeholder="Enter questionnaire title"></el-input>
        </el-form-item>
        <el-form-item label="Description" prop="description">
          <el-input
            v-model="editingQuestionnaire.description"
            type="textarea"
            :rows="3"
            placeholder="Enter questionnaire description"
          ></el-input>
        </el-form-item>
        <el-form-item label="Phase" prop="phase">
          <el-select v-model="editingQuestionnaire.phase" placeholder="Select phase">
            <el-option label="Phase 1 - Maturity Assessment" value="1"></el-option>
            <el-option label="Phase 2 - Competency Assessment" value="2"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Status" prop="status">
          <el-select v-model="editingQuestionnaire.status" placeholder="Select status">
            <el-option label="Draft" value="draft"></el-option>
            <el-option label="Active" value="active"></el-option>
            <el-option label="Archived" value="archived"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Instructions">
          <el-input
            v-model="editingQuestionnaire.instructions"
            type="textarea"
            :rows="4"
            placeholder="Enter instructions for users taking this assessment"
          ></el-input>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="closeQuestionnaireDialog">Cancel</el-button>
          <el-button type="primary" @click="saveQuestionnaire" :loading="saving">
            {{ editingQuestionnaire.id ? 'Update' : 'Create' }}
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- Question Dialog -->
    <el-dialog
      v-model="questionDialogVisible"
      :title="editingQuestion.id ? 'Edit Question' : 'Create Question'"
      width="70%"
      :before-close="closeQuestionDialog"
    >
      <el-form
        :model="editingQuestion"
        :rules="questionRules"
        ref="questionForm"
        label-width="150px"
      >
        <el-form-item label="Question Text" prop="text">
          <el-input
            v-model="editingQuestion.text"
            type="textarea"
            :rows="3"
            placeholder="Enter the question text"
          ></el-input>
        </el-form-item>
        <el-form-item label="Question Type" prop="type">
          <el-select v-model="editingQuestion.type" @change="onQuestionTypeChange">
            <el-option label="Multiple Choice" value="multiple_choice"></el-option>
            <el-option label="Single Choice" value="single_choice"></el-option>
            <el-option label="Rating Scale (1-5)" value="rating"></el-option>
            <el-option label="Text Input" value="text"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="Competency" prop="competencyId">
          <el-select v-model="editingQuestion.competencyId" placeholder="Select competency">
            <el-option
              v-for="comp in competencies"
              :key="comp.id"
              :label="comp.name"
              :value="comp.id"
            ></el-option>
          </el-select>
        </el-form-item>
        <el-form-item
          v-if="editingQuestion.type === 'multiple_choice' || editingQuestion.type === 'single_choice'"
          label="Options"
        >
          <div class="question-options">
            <div
              v-for="(option, index) in editingQuestion.options"
              :key="index"
              class="option-row"
            >
              <el-input
                v-model="option.text"
                placeholder="Option text"
                class="option-input"
              ></el-input>
              <el-input-number
                v-model="option.score"
                :min="0"
                :max="100"
                class="option-score"
                placeholder="Score"
              ></el-input-number>
              <el-button
                type="danger"
                icon="el-icon-delete"
                @click="removeOption(index)"
                size="small"
              ></el-button>
            </div>
            <el-button @click="addOption" type="primary" size="small">
              <i class="el-icon-plus"></i> Add Option
            </el-button>
          </div>
        </el-form-item>
        <el-form-item label="Required" prop="required">
          <el-switch v-model="editingQuestion.required"></el-switch>
        </el-form-item>
        <el-form-item label="Help Text">
          <el-input
            v-model="editingQuestion.helpText"
            type="textarea"
            :rows="2"
            placeholder="Optional help text for the question"
          ></el-input>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="closeQuestionDialog">Cancel</el-button>
          <el-button type="primary" @click="saveQuestion" :loading="saving">
            {{ editingQuestion.id ? 'Update' : 'Create' }}
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from '@/api/axios'

export default {
  name: 'AdminPanel',
  setup() {
    // Reactive data
    const activeTab = ref('questionnaires')
    const loading = ref({
      questionnaires: false,
      questions: false,
      results: false
    })
    const saving = ref(false)

    // Data arrays
    const questionnaires = ref([])
    const questions = ref([])
    const competencies = ref([])
    const assessmentResults = ref([])
    const selectedQuestions = ref([])

    // Filters
    const filters = ref({
      phase: '',
      status: '',
      search: ''
    })

    const questionFilters = ref({
      type: '',
      competency: '',
      search: ''
    })

    // Statistics
    const totalQuestionnaires = ref(0)
    const totalQuestions = ref(0)
    const totalUsers = ref(0)

    const resultsStats = ref({
      totalAssessments: 0,
      completedAssessments: 0,
      averageScore: 0,
      averageTime: 0
    })

    // Dialog visibility
    const questionnaireDialogVisible = ref(false)
    const questionDialogVisible = ref(false)

    // Editing objects
    const editingQuestionnaire = ref({
      id: null,
      title: '',
      description: '',
      phase: '',
      status: 'draft',
      instructions: ''
    })

    const editingQuestion = ref({
      id: null,
      text: '',
      type: 'single_choice',
      competencyId: '',
      options: [],
      required: true,
      helpText: ''
    })

    // Configuration
    const configuration = ref({
      maxAssessmentTime: 60,
      passingScore: 70,
      allowRetakes: true,
      maxRetakeAttempts: 3,
      showResultsImmediately: true,
      rag: {
        temperature: 0.7,
        maxTokens: 500,
        qualityThreshold: 85,
        autoValidation: true
      },
      notifications: {
        assessmentCompletion: true,
        weeklyReports: false,
        systemUpdates: true
      },
      retention: {
        assessmentResults: '2y',
        activityLogs: '6m',
        autoCleanup: true
      }
    })

    // Form rules
    const questionnaireRules = {
      title: [
        { required: true, message: 'Please enter title', trigger: 'blur' }
      ],
      description: [
        { required: true, message: 'Please enter description', trigger: 'blur' }
      ],
      phase: [
        { required: true, message: 'Please select phase', trigger: 'change' }
      ]
    }

    const questionRules = {
      text: [
        { required: true, message: 'Please enter question text', trigger: 'blur' }
      ],
      type: [
        { required: true, message: 'Please select question type', trigger: 'change' }
      ],
      competencyId: [
        { required: true, message: 'Please select competency', trigger: 'change' }
      ]
    }

    // Computed properties
    const filteredQuestionnaires = computed(() => {
      return questionnaires.value.filter(q => {
        if (filters.value.phase && q.phase !== filters.value.phase) return false
        if (filters.value.status && q.status !== filters.value.status) return false
        if (filters.value.search && !q.title.toLowerCase().includes(filters.value.search.toLowerCase())) return false
        return true
      })
    })

    const filteredQuestions = computed(() => {
      return questions.value.filter(q => {
        if (questionFilters.value.type && q.type !== questionFilters.value.type) return false
        if (questionFilters.value.competency && q.competencyId !== questionFilters.value.competency) return false
        if (questionFilters.value.search && !q.text.toLowerCase().includes(questionFilters.value.search.toLowerCase())) return false
        return true
      })
    })

    // Methods
    const loadQuestionnaires = async () => {
      loading.value.questionnaires = true
      try {
        const response = await axios.get('/api/admin/questionnaires')
        questionnaires.value = response.data.questionnaires
        totalQuestionnaires.value = response.data.total
      } catch (error) {
        console.error('Error loading questionnaires:', error)
        ElMessage.error('Failed to load questionnaires')
      } finally {
        loading.value.questionnaires = false
      }
    }

    const loadQuestions = async () => {
      loading.value.questions = true
      try {
        const response = await axios.get('/api/admin/questions')
        questions.value = response.data.questions
        totalQuestions.value = response.data.total
      } catch (error) {
        console.error('Error loading questions:', error)
        ElMessage.error('Failed to load questions')
      } finally {
        loading.value.questions = false
      }
    }

    const loadCompetencies = async () => {
      try {
        const response = await axios.get('/api/competencies')
        competencies.value = response.data
      } catch (error) {
        console.error('Error loading competencies:', error)
      }
    }

    const loadResults = async () => {
      loading.value.results = true
      try {
        const response = await axios.get('/api/admin/assessment-results')
        assessmentResults.value = response.data.results
        resultsStats.value = response.data.stats
      } catch (error) {
        console.error('Error loading results:', error)
        ElMessage.error('Failed to load assessment results')
      } finally {
        loading.value.results = false
      }
    }

    const loadConfiguration = async () => {
      try {
        const response = await axios.get('/api/admin/configuration')
        configuration.value = { ...configuration.value, ...response.data }
      } catch (error) {
        console.error('Error loading configuration:', error)
      }
    }

    const showCreateQuestionnaire = () => {
      editingQuestionnaire.value = {
        id: null,
        title: '',
        description: '',
        phase: '',
        status: 'draft',
        instructions: ''
      }
      questionnaireDialogVisible.value = true
    }

    const editQuestionnaire = (questionnaire) => {
      editingQuestionnaire.value = { ...questionnaire }
      questionnaireDialogVisible.value = true
    }

    const closeQuestionnaireDialog = () => {
      questionnaireDialogVisible.value = false
    }

    const saveQuestionnaire = async () => {
      saving.value = true
      try {
        const url = editingQuestionnaire.value.id
          ? `/api/admin/questionnaires/${editingQuestionnaire.value.id}`
          : '/api/admin/questionnaires'

        const method = editingQuestionnaire.value.id ? 'put' : 'post'
        await axios[method](url, editingQuestionnaire.value)

        ElMessage.success(`Questionnaire ${editingQuestionnaire.value.id ? 'updated' : 'created'} successfully`)
        questionnaireDialogVisible.value = false
        await loadQuestionnaires()
      } catch (error) {
        console.error('Error saving questionnaire:', error)
        ElMessage.error('Failed to save questionnaire')
      } finally {
        saving.value = false
      }
    }

    const deleteQuestionnaire = (questionnaire) => {
      ElMessageBox.confirm(
        `Are you sure you want to delete "${questionnaire.title}"?`,
        'Delete Questionnaire',
        {
          confirmButtonText: 'Delete',
          cancelButtonText: 'Cancel',
          type: 'warning'
        }
      ).then(async () => {
        try {
          await axios.delete(`/api/admin/questionnaires/${questionnaire.id}`)
          ElMessage.success('Questionnaire deleted successfully')
          await loadQuestionnaires()
        } catch (error) {
          console.error('Error deleting questionnaire:', error)
          ElMessage.error('Failed to delete questionnaire')
        }
      }).catch(() => {
        // User cancelled
      })
    }

    const duplicateQuestionnaire = async (questionnaire) => {
      try {
        await axios.post(`/api/admin/questionnaires/${questionnaire.id}/duplicate`)
        ElMessage.success('Questionnaire duplicated successfully')
        await loadQuestionnaires()
      } catch (error) {
        console.error('Error duplicating questionnaire:', error)
        ElMessage.error('Failed to duplicate questionnaire')
      }
    }

    const manageQuestions = (questionnaire) => {
      // Navigate to questions tab with filter
      activeTab.value = 'questions'
      // Could implement questionnaire-specific filtering here
    }

    const showCreateQuestion = () => {
      editingQuestion.value = {
        id: null,
        text: '',
        type: 'single_choice',
        competencyId: '',
        options: [
          { text: '', score: 0 },
          { text: '', score: 0 }
        ],
        required: true,
        helpText: ''
      }
      questionDialogVisible.value = true
    }

    const editQuestion = (question) => {
      editingQuestion.value = { ...question }
      if (!editingQuestion.value.options) {
        editingQuestion.value.options = []
      }
      questionDialogVisible.value = true
    }

    const closeQuestionDialog = () => {
      questionDialogVisible.value = false
    }

    const saveQuestion = async () => {
      saving.value = true
      try {
        const url = editingQuestion.value.id
          ? `/api/admin/questions/${editingQuestion.value.id}`
          : '/api/admin/questions'

        const method = editingQuestion.value.id ? 'put' : 'post'
        await axios[method](url, editingQuestion.value)

        ElMessage.success(`Question ${editingQuestion.value.id ? 'updated' : 'created'} successfully`)
        questionDialogVisible.value = false
        await loadQuestions()
      } catch (error) {
        console.error('Error saving question:', error)
        ElMessage.error('Failed to save question')
      } finally {
        saving.value = false
      }
    }

    const deleteQuestion = (question) => {
      ElMessageBox.confirm(
        'Are you sure you want to delete this question?',
        'Delete Question',
        {
          confirmButtonText: 'Delete',
          cancelButtonText: 'Cancel',
          type: 'warning'
        }
      ).then(async () => {
        try {
          await axios.delete(`/api/admin/questions/${question.id}`)
          ElMessage.success('Question deleted successfully')
          await loadQuestions()
        } catch (error) {
          console.error('Error deleting question:', error)
          ElMessage.error('Failed to delete question')
        }
      }).catch(() => {
        // User cancelled
      })
    }

    const onQuestionTypeChange = () => {
      if (editingQuestion.value.type === 'multiple_choice' || editingQuestion.value.type === 'single_choice') {
        if (!editingQuestion.value.options || editingQuestion.value.options.length === 0) {
          editingQuestion.value.options = [
            { text: '', score: 0 },
            { text: '', score: 0 }
          ]
        }
      } else {
        editingQuestion.value.options = []
      }
    }

    const addOption = () => {
      editingQuestion.value.options.push({ text: '', score: 0 })
    }

    const removeOption = (index) => {
      editingQuestion.value.options.splice(index, 1)
    }

    const saveConfiguration = async () => {
      saving.value = true
      try {
        await axios.put('/api/admin/configuration', configuration.value)
        ElMessage.success('Configuration saved successfully')
      } catch (error) {
        console.error('Error saving configuration:', error)
        ElMessage.error('Failed to save configuration')
      } finally {
        saving.value = false
      }
    }

    const resetConfiguration = () => {
      ElMessageBox.confirm(
        'This will reset all configuration to default values. Continue?',
        'Reset Configuration',
        {
          confirmButtonText: 'Reset',
          cancelButtonText: 'Cancel',
          type: 'warning'
        }
      ).then(() => {
        loadConfiguration()
        ElMessage.success('Configuration reset to defaults')
      }).catch(() => {
        // User cancelled
      })
    }

    // Utility methods
    const getPhaseType = (phase) => {
      const types = { '1': 'primary', '2': 'success' }
      return types[phase] || 'info'
    }

    const getStatusType = (status) => {
      const types = {
        active: 'success',
        draft: 'warning',
        archived: 'info'
      }
      return types[status] || 'info'
    }

    const getQuestionTypeColor = (type) => {
      const colors = {
        multiple_choice: 'primary',
        single_choice: 'success',
        rating: 'warning',
        text: 'info'
      }
      return colors[type] || 'info'
    }

    const getQuestionRowClass = ({ row }) => {
      return row.questionnaireName ? '' : 'unassigned-question'
    }

    const formatDate = (date) => {
      if (!date) return ''
      return new Date(date).toLocaleDateString()
    }

    const formatDateTime = (date) => {
      if (!date) return ''
      return new Date(date).toLocaleString()
    }

    // Lifecycle
    onMounted(async () => {
      await Promise.all([
        loadQuestionnaires(),
        loadQuestions(),
        loadCompetencies(),
        loadResults(),
        loadConfiguration()
      ])
    })

    return {
      activeTab,
      loading,
      saving,
      questionnaires,
      questions,
      competencies,
      assessmentResults,
      selectedQuestions,
      filters,
      questionFilters,
      totalQuestionnaires,
      totalQuestions,
      totalUsers,
      resultsStats,
      questionnaireDialogVisible,
      questionDialogVisible,
      editingQuestionnaire,
      editingQuestion,
      configuration,
      questionnaireRules,
      questionRules,
      filteredQuestionnaires,
      filteredQuestions,
      loadQuestionnaires,
      loadQuestions,
      loadResults,
      showCreateQuestionnaire,
      editQuestionnaire,
      closeQuestionnaireDialog,
      saveQuestionnaire,
      deleteQuestionnaire,
      duplicateQuestionnaire,
      manageQuestions,
      showCreateQuestion,
      editQuestion,
      closeQuestionDialog,
      saveQuestion,
      deleteQuestion,
      onQuestionTypeChange,
      addOption,
      removeOption,
      saveConfiguration,
      resetConfiguration,
      getPhaseType,
      getStatusType,
      getQuestionTypeColor,
      getQuestionRowClass,
      formatDate,
      formatDateTime
    }
  }
}
</script>

<style scoped>
.admin-panel {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding: 25px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  color: white;
}

.header-content h1 {
  margin: 0;
  font-size: 2.2em;
}

.header-content p {
  margin: 5px 0 0 0;
  opacity: 0.9;
}

.header-stats {
  display: flex;
  gap: 20px;
}

.stat-card {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 8px;
  padding: 15px 20px;
  text-align: center;
  min-width: 100px;
}

.stat-value {
  font-size: 2em;
  font-weight: bold;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 0.9em;
  opacity: 0.9;
}

.admin-tabs {
  margin-bottom: 30px;
}

.tab-content {
  min-height: 600px;
}

.content-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
  padding-bottom: 15px;
  border-bottom: 2px solid #f0f0f0;
}

.content-header h2 {
  margin: 0;
  color: #2c3e50;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.filters-section {
  margin-bottom: 20px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
}

.questionnaire-title strong {
  color: #2c3e50;
  font-size: 16px;
}

.questionnaire-description {
  margin: 5px 0 0 0;
  color: #7f8c8d;
  font-size: 14px;
}

.question-badge {
  margin-right: 10px;
}

.danger-button {
  color: #f56c6c;
}

.danger-button:hover {
  color: #f78989;
}

.question-cell {
  padding: 5px 0;
}

.question-text {
  font-weight: 500;
  color: #2c3e50;
  margin-bottom: 8px;
}

.question-meta {
  display: flex;
  gap: 10px;
  align-items: center;
}

.competency-tag {
  color: #7f8c8d;
  font-size: 12px;
}

.batch-actions {
  margin-top: 20px;
  padding: 20px;
  background: #f8f9fa;
  border-radius: 8px;
  display: flex;
  gap: 15px;
  justify-content: center;
}

.results-overview {
  margin-bottom: 30px;
}

.overview-card {
  border: none;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.overview-stat {
  display: flex;
  align-items: center;
  gap: 15px;
}

.stat-icon {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 20px;
}

.stat-content {
  flex: 1;
}

.stat-number {
  font-size: 2em;
  font-weight: bold;
  color: #2c3e50;
  margin-bottom: 5px;
}

.config-card {
  margin-bottom: 20px;
}

.question-options {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 15px;
  background: #fafafa;
}

.option-row {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
  align-items: center;
}

.option-input {
  flex: 1;
}

.option-score {
  width: 120px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

/* Table row classes */
.unassigned-question {
  background-color: #fff7e6 !important;
}

/* Responsive design */
@media (max-width: 1200px) {
  .page-header {
    flex-direction: column;
    gap: 20px;
    text-align: center;
  }

  .header-stats {
    justify-content: center;
  }

  .content-header {
    flex-direction: column;
    gap: 15px;
    align-items: flex-start;
  }
}

@media (max-width: 768px) {
  .admin-panel {
    padding: 10px;
  }

  .filters-section .el-row {
    flex-direction: column;
  }

  .filters-section .el-col {
    margin-bottom: 10px;
  }
}
</style>