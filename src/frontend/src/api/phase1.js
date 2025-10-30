/**
 * Phase 1 API Service
 * Handles all Phase 1 related API calls (Maturity, Roles, Strategy)
 */

import axiosInstance from './axios';

/**
 * Phase 1 Task 1: Maturity Assessment APIs
 */
export const maturityApi = {
  /**
   * Calculate maturity score from answers (client-side calculation)
   * This is done in frontend but can also be verified with backend
   * @param {Object} answers - { rolloutScope, seRolesProcesses, seMindset, knowledgeBase }
   * @returns {Promise} Calculation results
   */
  calculate: async (answers) => {
    try {
      const response = await axiosInstance.post('/api/phase1/maturity/calculate', {
        answers
      });
      return response.data;
    } catch (error) {
      console.error('Maturity calculation failed:', error);
      throw error;
    }
  },

  /**
   * Save maturity assessment to database
   * @param {Number} orgId - Organization ID
   * @param {Object} answers - Question answers
   * @param {Object} results - Calculation results
   * @returns {Promise} Save response
   */
  save: async (orgId, answers, results) => {
    try {
      const response = await axiosInstance.post('/api/phase1/maturity/save', {
        org_id: orgId,
        answers,
        results
      });
      return response.data;
    } catch (error) {
      console.error('Failed to save maturity assessment:', error);
      throw error;
    }
  },

  /**
   * Get latest maturity assessment for an organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Latest maturity assessment data
   */
  get: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/maturity/${orgId}/latest`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch maturity assessment:', error);
      throw error;
    }
  },

  /**
   * Get all maturity assessments for an organization (history)
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Array of maturity assessments
   */
  getHistory: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/maturity/${orgId}/history`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch maturity history:', error);
      throw error;
    }
  },

  /**
   * Delete maturity assessment
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Delete response
   */
  delete: async (orgId) => {
    try {
      const response = await axiosInstance.delete(`/api/phase1/maturity/${orgId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to delete maturity assessment:', error);
      throw error;
    }
  }
};

/**
 * Phase 1 Task 2: Role Identification APIs
 */
export const rolesApi = {
  /**
   * Get standard SE role clusters from new Phase1 endpoint
   * @returns {Promise} List of 14 SE role clusters
   */
  getStandardRoles: async () => {
    try {
      const response = await axiosInstance.get('/api/phase1/roles/standard');
      return response.data;
    } catch (error) {
      console.error('Failed to fetch standard SE roles:', error);
      throw error;
    }
  },

  /**
   * Save identified SE roles for an organization
   * @param {Number} orgId - Organization ID
   * @param {Number} maturityId - Maturity assessment ID
   * @param {Array} roles - Array of role objects
   * @param {String} identificationMethod - 'STANDARD' or 'TASK_BASED'
   * @returns {Promise} Save response
   */
  save: async (orgId, maturityId, roles, identificationMethod = 'STANDARD') => {
    try {
      const response = await axiosInstance.post('/api/phase1/roles/save', {
        org_id: orgId,
        maturity_id: maturityId,
        roles,
        identification_method: identificationMethod
      });
      return response.data;
    } catch (error) {
      console.error('Failed to save Phase1 roles:', error);
      throw error;
    }
  },

  /**
   * Get all identified roles for an organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} List of identified roles
   */
  get: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/roles/${orgId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch Phase1 roles:', error);
      throw error;
    }
  },

  /**
   * Get latest identified roles for an organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Latest identified roles
   */
  getLatest: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/roles/${orgId}/latest`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch latest Phase1 roles:', error);
      throw error;
    }
  },

  /**
   * Map tasks to ISO processes using AI (reuses existing /findProcesses endpoint)
   * Used in task-based role identification pathway
   * @param {String} username - Username for task analysis
   * @param {Number} organizationId - Organization ID
   * @param {Object} tasks - { responsible_for, supporting, designing }
   * @returns {Promise} Process mapping results
   */
  mapTasksToProcesses: async (username, organizationId, tasks) => {
    try {
      const response = await axiosInstance.post('/findProcesses', {
        username,
        organizationId,
        tasks
      });
      return response.data;
    } catch (error) {
      console.error('Failed to map tasks to processes:', error);
      throw error;
    }
  },

  /**
   * Suggest SE role based on process involvement
   * Uses process matching algorithm to find the best role match
   * @param {String} username - Username identifier
   * @param {Number} organizationId - Organization ID
   * @param {Array} processes - Array of process objects with process_name and involvement
   * @returns {Promise} Suggested role with confidence score
   */
  suggestRoleFromProcesses: async (username, organizationId, processes) => {
    try {
      const response = await axiosInstance.post('/api/phase1/roles/suggest-from-processes', {
        username,
        organizationId,
        processes
      });
      return response.data;
    } catch (error) {
      console.error('Failed to suggest role from processes:', error);
      throw error;
    }
  },

  /**
   * Initialize role-process matrix for newly saved roles
   * Called after roles are saved to organization_roles table
   * @param {Number} organizationId - Organization ID
   * @param {Array} roles - Array of saved role objects with IDs
   * @param {Boolean} smartMerge - If true, only initialize matrix for new roles (preserves existing)
   * @returns {Promise} Initialization result
   */
  initializeMatrix: async (organizationId, roles, smartMerge = false) => {
    try {
      const response = await axiosInstance.post('/api/phase1/roles/initialize-matrix', {
        organization_id: organizationId,
        roles,
        smart_merge: smartMerge
      });
      return response.data;
    } catch (error) {
      console.error('Failed to initialize role-process matrix:', error);
      throw error;
    }
  }
};

/**
 * Phase 1 Task 2: Target Group Size APIs
 */
export const targetGroupApi = {
  /**
   * Save target group size information
   * @param {Number} orgId - Organization ID
   * @param {Number} maturityId - Maturity assessment ID
   * @param {Object} sizeData - Size data object
   * @returns {Promise} Save response
   */
  save: async (orgId, maturityId, sizeData) => {
    try {
      const response = await axiosInstance.post('/api/phase1/target-group/save', {
        org_id: orgId,
        maturity_id: maturityId,
        sizeData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to save target group size:', error);
      throw error;
    }
  },

  /**
   * Get target group size for an organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Target group size data
   */
  get: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/target-group/${orgId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch target group size:', error);
      throw error;
    }
  }
};

/**
 * Phase 1 Task 3: Strategy Selection APIs
 */
export const strategyApi = {
  /**
   * Get all strategy definitions (7 SE training strategies)
   * @returns {Promise} List of strategy definitions
   */
  getDefinitions: async () => {
    try {
      const response = await axiosInstance.get('/api/phase1/strategies/definitions');
      return response.data;
    } catch (error) {
      console.error('Failed to fetch strategy definitions:', error);
      throw error;
    }
  },

  /**
   * Calculate recommended strategies based on maturity and target group
   * @param {Object} maturityData - Maturity assessment results
   * @param {Object} targetGroupData - Target group size data
   * @returns {Promise} Strategy recommendations with decision path and reasoning
   */
  calculate: async (maturityData, targetGroupData) => {
    try {
      const response = await axiosInstance.post('/api/phase1/strategies/calculate', {
        maturityData,
        targetGroupData
      });
      return response.data;
    } catch (error) {
      console.error('Failed to calculate strategies:', error);
      throw error;
    }
  },

  /**
   * Save selected strategies to database
   * @param {Number} orgId - Organization ID
   * @param {Number} maturityId - Maturity assessment ID
   * @param {Array} strategies - Selected strategy objects
   * @param {Array} decisionPath - Decision path array
   * @param {String} userPreference - User's secondary strategy choice (for low-maturity orgs)
   * @returns {Promise} Save response
   */
  save: async (orgId, maturityId, strategies, decisionPath, userPreference = null) => {
    try {
      const response = await axiosInstance.post('/api/phase1/strategies/save', {
        orgId,
        maturityId,
        strategies,
        decisionPath,
        userPreference
      });
      return response.data;
    } catch (error) {
      console.error('Failed to save strategies:', error);
      throw error;
    }
  },

  /**
   * Get all strategy selections for an organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} List of all strategy selections
   */
  get: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/strategies/${orgId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch strategies:', error);
      throw error;
    }
  },

  /**
   * Get latest strategy selection for an organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Latest strategy selection
   */
  getLatest: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/strategies/${orgId}/latest`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch latest strategies:', error);
      throw error;
    }
  }
};

/**
 * General Phase 1 APIs
 */
export const phase1Api = {
  /**
   * Get complete Phase 1 summary for an organization
   * @param {Number} orgId - Organization ID
   * @returns {Promise} Complete Phase 1 data
   */
  getSummary: async (orgId) => {
    try {
      const response = await axiosInstance.get(`/api/phase1/summary/${orgId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch Phase 1 summary:', error);
      throw error;
    }
  },

  /**
   * Mark Phase 1 as complete
   * @param {Number} orgId - Organization ID
   * @param {Object} data - Complete Phase 1 data
   * @returns {Promise} Completion response
   */
  complete: async (orgId, data) => {
    try {
      const response = await axiosInstance.post('/api/phase1/complete', {
        org_id: orgId,
        ...data
      });
      return response.data;
    } catch (error) {
      console.error('Failed to complete Phase 1:', error);
      throw error;
    }
  }
};

// Export all APIs as a single object
export default {
  maturity: maturityApi,
  roles: rolesApi,
  targetGroup: targetGroupApi,
  strategy: strategyApi,
  phase1: phase1Api
};
