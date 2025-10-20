import axios from './axios'

export const seqptApi = {
  // SE-QPT 4-Phase Workflow

  // Phase 1: Prepare SE Training
  phase1: {
    getOrganizationMaturity: () => {
      return axios.get('/api/seqpt/phase1/maturity')
    },

    submitMaturityAssessment: (maturityData) => {
      return axios.post('/api/seqpt/phase1/maturity', {
        organization_name: maturityData.organizationName,
        industry_domain: maturityData.industryDomain,
        organization_size: maturityData.organizationSize,
        current_practices: maturityData.currentPractices,
        process_maturity: maturityData.processMaturity,
        tool_usage: maturityData.toolUsage,
        team_experience: maturityData.teamExperience
      })
    },

    getArchetypes: () => {
      return axios.get('/api/seqpt/phase1/archetypes')
    },

    selectArchetype: (archetypeId, assessmentId) => {
      return axios.post('/api/seqpt/phase1/select-archetype', {
        archetype_id: archetypeId,
        assessment_id: assessmentId
      })
    }
  },

  // Phase 2: Identify Requirements and Competencies
  phase2: {
    getCompetencies: () => {
      return axios.get('/api/seqpt/phase2/competencies')
    },

    getRoles: () => {
      return axios.get('/api/seqpt/phase2/roles')
    },

    getRoleCompetencyMatrix: () => {
      return axios.get('/api/seqpt/phase2/role-competency-matrix')
    },

    submitCompetencyAssessment: (assessmentData) => {
      return axios.post('/api/seqpt/phase2/assess-competencies', {
        assessment_id: assessmentData.assessmentId,
        target_role_id: assessmentData.targetRoleId,
        competency_responses: assessmentData.competencyResponses,
        job_description: assessmentData.jobDescription
      })
    },

    generateObjectives: (objectiveData) => {
      return axios.post('/api/seqpt/phase2/generate-objectives', {
        assessment_id: objectiveData.assessmentId,
        competency_gaps: objectiveData.competencyGaps,
        company_context: objectiveData.companyContext,
        target_role: objectiveData.targetRole,
        selected_archetype: objectiveData.selectedArchetype
      })
    },

    validateObjectives: (objectives) => {
      return axios.post('/api/seqpt/phase2/validate-objectives', {
        objectives: objectives
      })
    }
  },

  // Phase 3: Macro Planning
  phase3: {
    getModules: () => {
      return axios.get('/api/seqpt/phase3/modules')
    },

    getModuleRecommendations: (assessmentId) => {
      return axios.get(`/api/seqpt/phase3/module-recommendations/${assessmentId}`)
    },

    selectModules: (selectionData) => {
      return axios.post('/api/seqpt/phase3/select-modules', {
        assessment_id: selectionData.assessmentId,
        selected_modules: selectionData.selectedModules,
        learning_formats: selectionData.learningFormats,
        timeline_preferences: selectionData.timelinePreferences
      })
    },

    optimizeFormats: (optimizationData) => {
      return axios.post('/api/seqpt/phase3/optimize-formats', {
        selected_modules: optimizationData.selectedModules,
        learner_preferences: optimizationData.learnerPreferences,
        resource_constraints: optimizationData.resourceConstraints,
        time_constraints: optimizationData.timeConstraints
      })
    }
  },

  // Phase 4: Micro Planning
  phase4: {
    findCohorts: (assessmentId) => {
      return axios.get(`/api/seqpt/phase4/find-cohorts/${assessmentId}`)
    },

    createQualificationPlan: (planData) => {
      return axios.post('/api/seqpt/phase4/create-plan', {
        assessment_id: planData.assessmentId,
        plan_name: planData.planName,
        description: planData.description,
        target_role_id: planData.targetRoleId,
        selected_archetype_id: planData.selectedArchetypeId,
        learning_objectives: planData.learningObjectives,
        selected_modules: planData.selectedModules,
        learning_formats: planData.learningFormats,
        planned_start_date: planData.plannedStartDate,
        planned_end_date: planData.plannedEndDate,
        estimated_duration_weeks: planData.estimatedDurationWeeks,
        resource_requirements: planData.resourceRequirements
      })
    },

    joinCohort: (cohortId, planId) => {
      return axios.post('/api/seqpt/phase4/join-cohort', {
        cohort_id: cohortId,
        plan_id: planId
      })
    },

    getPersonalizedPlan: (planUuid) => {
      return axios.get(`/api/seqpt/phase4/personalized-plan/${planUuid}`)
    }
  },

  // Company Context Management
  context: {
    extractContext: (contextData) => {
      return axios.post('/api/seqpt/context/extract', {
        company_name: contextData.companyName,
        industry_domain: contextData.industryDomain,
        business_domain: contextData.businessDomain,
        company_description: contextData.companyDescription,
        current_processes: contextData.currentProcesses,
        tools_used: contextData.toolsUsed,
        regulatory_requirements: contextData.regulatoryRequirements
      })
    },

    getContext: (contextId) => {
      return axios.get(`/api/seqpt/context/${contextId}`)
    },

    updateContext: (contextId, contextData) => {
      return axios.put(`/api/seqpt/context/${contextId}`, contextData)
    }
  },

  // Learning Objectives Management
  objectives: {
    getObjectives: (params = {}) => {
      return axios.get('/api/seqpt/objectives', { params })
    },

    generateObjective: (objectiveData) => {
      return axios.post('/api/seqpt/objectives/generate', {
        competency_id: objectiveData.competencyId,
        target_role_id: objectiveData.targetRoleId,
        archetype_id: objectiveData.archetypeId,
        company_context_id: objectiveData.companyContextId,
        difficulty_level: objectiveData.difficultyLevel
      })
    },

    validateObjective: (objectiveText) => {
      return axios.post('/api/seqpt/objectives/validate', {
        objective_text: objectiveText
      })
    },

    approveObjective: (objectiveId) => {
      return axios.post(`/api/seqpt/objectives/${objectiveId}/approve`)
    },

    rejectObjective: (objectiveId, reason) => {
      return axios.post(`/api/seqpt/objectives/${objectiveId}/reject`, {
        reason: reason
      })
    }
  },

  // RAG System Management
  rag: {
    getStatus: () => {
      return axios.get('/api/seqpt/rag/status')
    },

    updateVectorDatabase: () => {
      return axios.post('/api/seqpt/rag/update-vectordb')
    },

    searchTemplates: (query) => {
      return axios.post('/api/seqpt/rag/search-templates', {
        query: query
      })
    },

    testGeneration: (testData) => {
      return axios.post('/api/seqpt/rag/test-generation', {
        competency: testData.competency,
        role: testData.role,
        archetype: testData.archetype,
        context: testData.context
      })
    }
  },

  // Progress Tracking
  progress: {
    trackProgress: (planUuid, progressData) => {
      return axios.post(`/api/seqpt/progress/${planUuid}`, {
        competency_id: progressData.competencyId,
        module_id: progressData.moduleId,
        progress_percentage: progressData.progressPercentage,
        status: progressData.status,
        notes: progressData.notes
      })
    },

    getProgress: (planUuid) => {
      return axios.get(`/api/seqpt/progress/${planUuid}`)
    }
  },

  // System Status and Health
  system: {
    getStatus: () => {
      return axios.get('/api/system/status')
    },

    getHealth: () => {
      return axios.get('/health')
    }
  }
}