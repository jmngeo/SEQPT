/**
 * Phase 2 API Service
 * Handles all Phase 2 related API calls (Competency Assessment & Learning Objectives)
 */

import axiosInstance from './axios';

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
      const response = await axiosInstance.get(`/api/phase2/identified-roles/${orgId}`);
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
      const response = await axiosInstance.post('/api/phase2/calculate-competencies', {
        org_id: orgId,
        role_ids: roleIds
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
   * @returns {Promise} Assessment ID and metadata
   */
  startAssessment: async (orgId, adminUserId, employeeName, roleIds, competencies, assessmentType = 'phase2_employee') => {
    try {
      const response = await axiosInstance.post('/api/phase2/start-assessment', {
        org_id: orgId,
        admin_user_id: adminUserId,
        employee_name: employeeName,
        role_ids: roleIds,
        competencies: competencies,
        assessment_type: assessmentType
      });
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
 * (To be implemented in Phase C)
 */
export const phase2Task3Api = {
  // Placeholder for Task 3 APIs
};

export default {
  task1: phase2Task1Api,
  task2: phase2Task2Api,
  task3: phase2Task3Api
};
