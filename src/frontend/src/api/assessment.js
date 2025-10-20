import axios from './axios'

export const assessmentApi = {
  // Assessment CRUD operations
  getAssessments: () => {
    return axios.get('/api/assessments')
  },

  getAssessment: (assessmentUuid) => {
    return axios.get(`/api/assessments/${assessmentUuid}`)
  },

  createAssessment: (assessmentData) => {
    return axios.post('/api/assessments', {
      type: assessmentData.type,
      phase: assessmentData.phase,
      organization_name: assessmentData.organizationName,
      industry_domain: assessmentData.industryDomain,
      organization_size: assessmentData.organizationSize
    })
  },

  updateAssessment: (assessmentUuid, updateData) => {
    return axios.put(`/api/assessments/${assessmentUuid}`, updateData)
  },

  deleteAssessment: (assessmentUuid) => {
    return axios.delete(`/api/assessments/${assessmentUuid}`)
  },

  // Assessment analytics
  getAnalytics: () => {
    return axios.get('/api/analytics/assessments')
  },

  getRecommendations: (assessmentId) => {
    return axios.get(`/api/recommendations/${assessmentId}`)
  },

  // Export functionality
  exportAssessment: (assessmentId) => {
    return axios.get(`/api/export/assessment/${assessmentId}`)
  },

  // Derik's assessment integration
  identifyProcesses: (jobDescription) => {
    return axios.post('/api/derik/public/identify-processes', {
      job_description: jobDescription
    })
  },

  rankCompetencies: (roleName, competencyName) => {
    return axios.post('/api/derik/rank-competencies', {
      role_name: roleName,
      competency_name: competencyName
    })
  },

  findSimilarRole: (jobDescription) => {
    return axios.post('/api/derik/find-similar-role', {
      job_description: jobDescription
    })
  },

  completeAssessment: (assessmentId, jobDescription, responses) => {
    return axios.post('/api/derik/complete-assessment', {
      assessment_id: assessmentId,
      job_description: jobDescription,
      responses: responses
    })
  },

  getCompetencyQuestionnaire: (competencyName) => {
    return axios.get(`/api/derik/questionnaire/${competencyName}`)
  },

  getAssessmentReport: (assessmentId) => {
    return axios.get(`/api/derik/assessment-report/${assessmentId}`)
  },

  getDerikStatus: () => {
    return axios.get('/api/derik/status')
  },

  // Questionnaire Management API
  getQuestionnaires: () => {
    return axios.get('/api/questionnaires')
  },

  getQuestionnaire: (questionnaireId, params = {}) => {
    return axios.get(`/api/questionnaires/${questionnaireId}`, { params })
  },

  startQuestionnaire: (questionnaireId) => {
    return axios.post(`/api/questionnaires/${questionnaireId}/start`)
  },

  submitAnswer: (responseUuid, answerData) => {
    return axios.post(`/api/responses/${responseUuid}/answer`, {
      question_id: answerData.questionId,
      question_response: answerData.questionResponse,
      text_response: answerData.textResponse,
      score_value: answerData.scoreValue
    })
  },

  completeQuestionnaire: (responseUuid) => {
    return axios.post(`/api/responses/${responseUuid}/complete`)
  },

  getResponse: (responseUuid) => {
    return axios.get(`/api/responses/${responseUuid}`)
  },

  getUserResponses: (userId) => {
    return axios.get(`/api/users/${userId}/responses`)
  },

  getUserQuestionnaireResponses: (userId) => {
    return axios.get(`/api/public/users/${userId}/responses`)
  },

  // Debug endpoint to verify server status
  getServerStatus: () => {
    return axios.get('/api/debug/server-status')
  },

  // Learning Module API
  getLearningModules: (params = {}) => {
    return axios.get('/api/modules', { params })
  },

  getLearningModule: (moduleCode) => {
    return axios.get(`/api/modules/${moduleCode}`)
  },

  getModuleRecommendations: () => {
    return axios.get('/api/modules/recommendations')
  },

  getLearningPaths: () => {
    return axios.get('/api/learning-paths')
  },

  getLearningPath: (pathUuid) => {
    return axios.get(`/api/learning-paths/${pathUuid}`)
  },

  enrollInModule: (moduleCode, enrollmentData) => {
    return axios.post('/api/enrollments', {
      module_code: moduleCode,
      ...enrollmentData
    })
  },

  getEnrollments: () => {
    return axios.get('/api/enrollments')
  }
}