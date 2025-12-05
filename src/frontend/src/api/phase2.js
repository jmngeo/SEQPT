/**
 * Phase 2 API Service
 * Handles all Phase 2 related API calls (Competency Assessment & Learning Objectives)
 */

import axiosInstance from './axios';

// Extended timeout for LLM-based operations (5 minutes)
const LLM_TIMEOUT = 300000;

/**
 * Phase 2 Task 1: Determine Necessary Competencies APIs
 */
export const phase2Task1Api = {
  /**
   * Get Phase 1 identified roles for an organization
   * Returns only roles with participating_in_training = true
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Identified roles data
   */
  getIdentifiedRoles: async (orgId) => {
    try {
      // Fetch roles from Phase 1 (where they are identified)
      const response = await axiosInstance.get(`/api/phase1/roles/${orgId}/latest`);
      return response.data;
    } catch (error) {
      console.error('[Phase2 API] Failed to fetch identified roles:', error);
      throw error;
    }
  },

  /**
   * Calculate necessary competencies for selected roles
   * Filters out competencies where role_competency_value = 0
   * @param {Number} orgId - Organization ID
   * @param {Array} roleIds - Array of Phase1Roles IDs
   * @returns {Promise} Calculated competencies and selected roles
   */
  calculateCompetencies: async (orgId, roleIds) => {
    try {
      const response = await axiosInstance.post('/api/get_required_competencies_for_roles', {
        organization_id: orgId,
        role_ids: roleIds,
        survey_type: 'known_roles'
      });
      return response.data;
    } catch (error) {
      console.error('[Phase2 API] Failed to calculate competencies:', error);
      throw error;
    }
  }
};

/**
 * Phase 2 Task 2: Identify Competency Gaps APIs
 */
export const phase2Task2Api = {
  /**
   * Start a new Phase 2 competency assessment
   * Creates an assessment record and links employee
   * @param {Number} orgId - Organization ID
   * @param {Number} adminUserId - Admin user ID
   * @param {String} employeeName - Employee name
   * @param {Array} roleIds - Phase1Role IDs from Task 1
   * @param {Array} competencies - Necessary competencies from Task 1
   * @param {String} assessmentType - Assessment type (default: 'phase2_employee')
   * @param {String} taskBasedUsername - Username for task-based pathway (optional)
   * @returns {Promise} Assessment ID and metadata
   */
  startAssessment: async (orgId, adminUserId, employeeName, roleIds, competencies, assessmentType = 'phase2_employee', taskBasedUsername = null) => {
    try {
      const payload = {
        org_id: orgId,
        admin_user_id: adminUserId,
        employee_name: employeeName,
        role_ids: roleIds,
        competencies: competencies,
        assessment_type: assessmentType
      }

      // Add task_based_username only if provided (for task-based pathway)
      if (taskBasedUsername) {
        payload.task_based_username = taskBasedUsername
      }

      const response = await axiosInstance.post('/api/phase2/start-assessment', payload);
      return response.data;
    } catch (error) {
      console.error('[Phase2 API] Failed to start assessment:', error);
      throw error;
    }
  },

  /**
   * Get assessment questions for a specific assessment
   * Returns only necessary competencies with their indicators
   * @param {Number} assessmentId - Assessment ID
   * @returns {Promise} Questions with competency indicators
   */
  getAssessmentQuestions: async (assessmentId) => {
    try {
      const response = await axiosInstance.get(`/api/phase2/assessment-questions/${assessmentId}`);
      return response.data;
    } catch (error) {
      console.error('[Phase2 API] Failed to fetch assessment questions:', error);
      throw error;
    }
  },

  /**
   * Submit assessment answers and calculate competency gaps
   * @param {Number} assessmentId - Assessment ID
   * @param {Array} answers - Array of {competency_id, selected_groups, current_level}
   * @returns {Promise} Gap analysis results
   */
  submitAssessment: async (assessmentId, answers) => {
    try {
      const response = await axiosInstance.post('/api/phase2/submit-assessment', {
        assessment_id: assessmentId,
        answers: answers
      });
      return response.data;
    } catch (error) {
      console.error('[Phase2 API] Failed to submit assessment:', error);
      throw error;
    }
  },

  /**
   * Get assessment results by assessment ID
   * @param {Number} assessmentId - Assessment ID
   * @returns {Promise} Assessment results with gaps and feedback
   */
  getAssessmentResults: async (assessmentId) => {
    try {
      const response = await axiosInstance.get(`/api/phase2/assessment-results/${assessmentId}`);
      return response.data;
    } catch (error) {
      console.error('[Phase2 API] Failed to fetch assessment results:', error);
      throw error;
    }
  }
};

/**
 * Phase 2 Task 3: Formulate Learning Objectives APIs (Admin Only)
 */
export const phase2Task3Api = {
  /**
   * Check prerequisites for learning objectives generation
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Validation result with readiness status
   */
  validatePrerequisites: async (orgId) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/prerequisites`
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to validate prerequisites:', error);

      // If 400 error, it's likely a validation failure (not an error)
      // Backend returns 400 with valid:false and error message
      if (error.response && error.response.status === 400 && error.response.data) {
        console.log('[Phase2 Task3 API] Prerequisites not met:', error.response.data);
        return error.response.data; // Return the validation result
      }

      throw error;
    }
  },

  /**
   * Quick validation check (without full generation)
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Strategy validation results
   */
  runQuickValidation: async (orgId) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/validation`
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to run validation:', error);
      throw error;
    }
  },

  /**
   * Get PMT context for organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} PMT context data
   */
  getPMTContext: async (orgId) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/pmt-context`
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to fetch PMT context:', error);
      throw error;
    }
  },

  /**
   * Save/update PMT context
   * @param {Number} orgId - Organization ID
   * @param {Object} pmtData - PMT context data (processes, methods, tools, industry, additionalContext)
   * @returns {Promise} Updated PMT context
   */
  savePMTContext: async (orgId, pmtData) => {
    try {
      const response = await axiosInstance.patch(
        `/api/phase2/learning-objectives/${orgId}/pmt-context`,
        pmtData
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to save PMT context:', error);
      throw error;
    }
  },

  /**
   * Generate learning objectives
   * @param {Number} orgId - Organization ID
   * @param {Object} options - Generation options (force: boolean for regeneration)
   * @returns {Promise} Generated learning objectives
   */
  generateObjectives: async (orgId, options = {}) => {
    try {
      const response = await axiosInstance.post(
        '/api/phase2/learning-objectives/generate',
        {
          organization_id: orgId,
          ...options
        },
        {
          timeout: LLM_TIMEOUT  // Extended timeout for LLM processing
        }
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to generate objectives:', error);
      throw error;
    }
  },

  /**
   * Get existing learning objectives
   * @param {Number} orgId - Organization ID
   * @param {Boolean} regenerate - Force regeneration
   * @returns {Promise} Learning objectives
   */
  getObjectives: async (orgId, regenerate = false) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}`,
        {
          params: { regenerate },
          timeout: LLM_TIMEOUT  // Extended timeout for LLM processing when regenerate=true
        }
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to fetch objectives:', error);
      throw error;
    }
  },

  /**
   * Get detailed list of users and their assessment status
   * @param {Number} orgId - Organization ID
   * @returns {Promise} User list with assessment status
   */
  getAssessmentUsers: async (orgId) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/users`
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to fetch assessment users:', error);
      throw error;
    }
  },

  /**
   * Export learning objectives
   * @param {Number} orgId - Organization ID
   * @param {String} format - 'pdf' | 'excel' | 'json'
   * @param {Object} filters - Optional filters (strategy, includeValidation)
   * @returns {Promise} File download
   */
  exportObjectives: async (orgId, format, filters = {}) => {
    try {
      const response = await axiosInstance.get(
        `/api/phase2/learning-objectives/${orgId}/export`,
        {
          params: {
            format,
            ...filters
          },
          responseType: 'blob' // For file download
        }
      );

      // Get filename from Content-Disposition header or generate default
      let filename = null;
      const contentDisposition = response.headers['content-disposition'];
      if (contentDisposition) {
        const filenameMatch = contentDisposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
        if (filenameMatch && filenameMatch[1]) {
          filename = filenameMatch[1].replace(/['"]/g, '');
        }
      }

      // Fallback filename with correct extension
      if (!filename) {
        const extensions = { excel: 'xlsx', pdf: 'pdf', json: 'json' };
        const ext = extensions[format] || format;
        const timestamp = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        filename = `learning_objectives_${timestamp}.${ext}`;
      }

      // Trigger download
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);

      return { success: true };
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to export objectives:', error);
      throw error;
    }
  },

  /**
   * Add a recommended strategy to organization's selected strategies
   * @param {Number} orgId - Organization ID
   * @param {String} strategyName - Name of strategy to add
   * @param {Object} pmtContext - PMT context (required if strategy needs deep customization)
   * @param {Boolean} regenerate - Whether to regenerate objectives after adding
   * @returns {Promise} Updated objectives if regenerate=true
   */
  addRecommendedStrategy: async (orgId, strategyName, pmtContext = null, regenerate = true) => {
    try {
      const payload = {
        strategy_name: strategyName,
        regenerate
      };

      // Add PMT context if provided
      if (pmtContext) {
        payload.pmt_context = pmtContext;
      }

      const response = await axiosInstance.post(
        `/api/phase2/learning-objectives/${orgId}/add-strategy`,
        payload
      );

      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to add strategy:', error);
      throw error;
    }
  },

  /**
   * Extract PMT information from an uploaded document
   * @param {Number} orgId - Organization ID
   * @param {File} file - Uploaded file (PDF, DOCX, TXT)
   * @returns {Promise} Extracted PMT data with confidence scores
   */
  extractPMTFromDocument: async (orgId, file) => {
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('organization_id', orgId);

      const response = await axiosInstance.post(
        '/api/phase2/extract-pmt-from-document',
        formData,
        {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        }
      );
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to extract PMT from document:', error);
      throw error;
    }
  },

  /**
   * Get list of available PMT reference example files
   * @returns {Promise} Array of example file metadata
   */
  getPMTReferenceExamples: async () => {
    try {
      const response = await axiosInstance.get('/api/phase2/pmt-reference-examples');
      return response.data;
    } catch (error) {
      console.error('[Phase2 Task3 API] Failed to fetch PMT examples:', error);
      throw error;
    }
  },

  /**
   * Get download URL for a PMT reference example file
   * @param {String} filename - Example filename to download
   * @returns {String} Download URL
   */
  getPMTExampleDownloadUrl: (filename) => {
    return `/api/phase2/pmt-reference-examples/${filename}`;
  }
};

export default {
  task1: phase2Task1Api,
  task2: phase2Task2Api,
  task3: phase2Task3Api
};
