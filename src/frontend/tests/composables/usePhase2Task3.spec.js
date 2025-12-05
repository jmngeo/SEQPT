import { describe, it, expect, beforeEach, vi } from 'vitest'
import { usePhase2Task3 } from '@/composables/usePhase2Task3'
import { phase2Task3Api } from '@/api/phase2'

// Mock the API module
vi.mock('@/api/phase2', () => ({
  phase2Task3Api: {
    validatePrerequisites: vi.fn(),
    getPMTContext: vi.fn(),
    savePMTContext: vi.fn(),
    getLearningObjectives: vi.fn(),
    generateLearningObjectives: vi.fn(),
    runValidation: vi.fn(),
    addRecommendedStrategy: vi.fn(),
    exportLearningObjectives: vi.fn(),
  }
}))

describe('usePhase2Task3', () => {
  const mockOrgId = 29

  beforeEach(() => {
    // Clear all mocks before each test
    vi.clearAllMocks()
  })

  describe('Initialization', () => {
    it('should initialize with correct default state', () => {
      const composable = usePhase2Task3(mockOrgId)

      expect(composable.isLoading.value).toBe(false)
      expect(composable.assessmentStats.value).toBe(null)
      expect(composable.selectedStrategiesCount.value).toBe(0)
      expect(composable.pmtContext.value).toBe(null)
      expect(composable.validationResults.value).toBe(null)
      expect(composable.learningObjectives.value).toBe(null)
      expect(composable.prerequisites.value).toBe(null)
      expect(composable.pathway.value).toBe(null)
      expect(composable.error.value).toBe(null)
    })

    it('should have correct computed properties', () => {
      const composable = usePhase2Task3(mockOrgId)

      expect(composable.hasObjectives.value).toBe(false)
      expect(composable.isReadyToGenerate.value).toBe(false)
      expect(composable.needsPMT.value).toBe(false)
      expect(composable.hasPMT.value).toBe(false)
    })
  })

  describe('fetchPrerequisites', () => {
    it('should fetch and set prerequisites successfully', async () => {
      const mockResponse = {
        completion_stats: {
          totalUsers: 40,
          usersWithAssessments: 35,
          completionRate: 87.5
        },
        has_assessments: true,
        has_strategies: true,
        needs_pmt: false,
        has_pmt: false,
        ready: true,
        pathway: 'ROLE_BASED',
        message: 'Prerequisites met',
        strategies_count: 2
      }

      phase2Task3Api.validatePrerequisites.mockResolvedValue(mockResponse)

      const composable = usePhase2Task3(mockOrgId)
      await composable.fetchPrerequisites()

      expect(phase2Task3Api.validatePrerequisites).toHaveBeenCalledWith(mockOrgId)
      expect(composable.assessmentStats.value).toEqual({
        totalUsers: 40,
        usersWithAssessments: 35,
        completionRate: 87.5
      })
      expect(composable.prerequisites.value.readyToGenerate).toBe(true)
      expect(composable.pathway.value).toBe('ROLE_BASED')
      expect(composable.selectedStrategiesCount.value).toBe(2)
    })

    it('should handle error response from prerequisites check', async () => {
      const mockErrorResponse = {
        ready: false,
        message: 'No assessments found',
        has_assessments: false,
        has_strategies: false
      }

      phase2Task3Api.validatePrerequisites.mockResolvedValue(mockErrorResponse)

      const composable = usePhase2Task3(mockOrgId)
      await composable.fetchPrerequisites()

      expect(composable.prerequisites.value.readyToGenerate).toBe(false)
      expect(composable.error.value).toBe('No assessments found')
    })
  })

  describe('fetchPMTContext', () => {
    it('should fetch PMT context successfully', async () => {
      const mockPMT = {
        processes: 'ISO 26262, V-model',
        methods: 'Agile, Scrum',
        tools: 'DOORS, JIRA',
        industry: 'Automotive',
        additionalContext: 'ADAS focus'
      }

      phase2Task3Api.getPMTContext.mockResolvedValue(mockPMT)

      const composable = usePhase2Task3(mockOrgId)
      await composable.fetchPMTContext()

      expect(phase2Task3Api.getPMTContext).toHaveBeenCalledWith(mockOrgId)
      expect(composable.pmtContext.value).toEqual(mockPMT)
    })

    it('should handle missing PMT context gracefully', async () => {
      phase2Task3Api.getPMTContext.mockRejectedValue(new Error('Not found'))

      const composable = usePhase2Task3(mockOrgId)
      await composable.fetchPMTContext()

      expect(composable.pmtContext.value).toBe(null)
    })
  })

  describe('savePMTContext', () => {
    it('should save PMT context and return saved data', async () => {
      const pmtData = {
        processes: 'ISO 26262',
        methods: 'Agile',
        tools: 'DOORS',
        industry: 'Automotive',
        additionalContext: ''
      }

      phase2Task3Api.savePMTContext.mockResolvedValue(pmtData)

      const composable = usePhase2Task3(mockOrgId)
      const result = await composable.savePMTContext(pmtData)

      expect(phase2Task3Api.savePMTContext).toHaveBeenCalledWith(mockOrgId, pmtData)
      expect(composable.pmtContext.value).toEqual(pmtData)
      expect(result).toEqual(pmtData)
    })
  })

  describe('fetchObjectives', () => {
    it('should fetch existing learning objectives', async () => {
      const mockObjectives = {
        pathway: 'ROLE_BASED',
        learningObjectivesByStrategy: {
          'SE for managers': {
            strategyName: 'SE for managers',
            coreCompetencies: [],
            trainableCompetencies: []
          }
        }
      }

      phase2Task3Api.getLearningObjectives.mockResolvedValue(mockObjectives)

      const composable = usePhase2Task3(mockOrgId)
      await composable.fetchObjectives()

      expect(phase2Task3Api.getLearningObjectives).toHaveBeenCalledWith(mockOrgId)
      expect(composable.learningObjectives.value).toEqual(mockObjectives.learningObjectivesByStrategy)
    })
  })

  describe('generateObjectives', () => {
    it('should generate learning objectives successfully', async () => {
      const mockResponse = {
        pathway: 'ROLE_BASED',
        learningObjectivesByStrategy: {
          'SE for managers': {
            strategyName: 'SE for managers',
            coreCompetencies: [],
            trainableCompetencies: [
              {
                competencyId: 11,
                competencyName: 'Decision Management',
                currentLevel: 2,
                targetLevel: 4,
                learningObjective: 'Participants are able to...'
              }
            ]
          }
        }
      }

      phase2Task3Api.generateLearningObjectives.mockResolvedValue(mockResponse)

      const composable = usePhase2Task3(mockOrgId)
      await composable.generateObjectives()

      expect(phase2Task3Api.generateLearningObjectives).toHaveBeenCalledWith(mockOrgId, undefined, false)
      expect(composable.learningObjectives.value).toEqual(mockResponse.learningObjectivesByStrategy)
      expect(composable.isLoading.value).toBe(false)
    })

    it('should handle generation with PMT context', async () => {
      const pmtContext = {
        processes: 'ISO 26262',
        tools: 'DOORS'
      }

      const mockResponse = {
        learningObjectivesByStrategy: {}
      }

      phase2Task3Api.generateLearningObjectives.mockResolvedValue(mockResponse)

      const composable = usePhase2Task3(mockOrgId)
      composable.pmtContext.value = pmtContext
      await composable.generateObjectives()

      expect(phase2Task3Api.generateLearningObjectives).toHaveBeenCalledWith(mockOrgId, pmtContext, false)
    })

    it('should handle force regeneration', async () => {
      const mockResponse = {
        learningObjectivesByStrategy: {}
      }

      phase2Task3Api.generateLearningObjectives.mockResolvedValue(mockResponse)

      const composable = usePhase2Task3(mockOrgId)
      await composable.generateObjectives({ force: true })

      expect(phase2Task3Api.generateLearningObjectives).toHaveBeenCalledWith(mockOrgId, null, true)
    })

    it('should handle generation errors', async () => {
      const errorMessage = 'PMT context required'
      phase2Task3Api.generateLearningObjectives.mockRejectedValue(new Error(errorMessage))

      const composable = usePhase2Task3(mockOrgId)

      await expect(composable.generateObjectives()).rejects.toThrow(errorMessage)
      expect(composable.isLoading.value).toBe(false)
    })
  })

  describe('runValidation', () => {
    it('should run validation and set results', async () => {
      const mockValidation = {
        status: 'GOOD',
        message: 'Strategy selection looks good',
        gapPercentage: 12.5,
        strategiesAdequate: true
      }

      phase2Task3Api.runValidation.mockResolvedValue(mockValidation)

      const composable = usePhase2Task3(mockOrgId)
      await composable.runValidation()

      expect(phase2Task3Api.runValidation).toHaveBeenCalledWith(mockOrgId)
      expect(composable.validationResults.value).toEqual(mockValidation)
      expect(composable.isLoading.value).toBe(false)
    })
  })

  describe('addRecommendedStrategy', () => {
    it('should add strategy without PMT', async () => {
      const strategyName = 'SE for managers'
      const mockResponse = {
        learningObjectivesByStrategy: {
          'SE for managers': {},
          'Continuous support': {}
        }
      }

      phase2Task3Api.addRecommendedStrategy.mockResolvedValue(mockResponse)

      const composable = usePhase2Task3(mockOrgId)
      await composable.addRecommendedStrategy(strategyName)

      expect(phase2Task3Api.addRecommendedStrategy).toHaveBeenCalledWith(mockOrgId, strategyName, null)
      expect(composable.learningObjectives.value).toEqual(mockResponse.learningObjectivesByStrategy)
    })

    it('should add strategy with PMT context', async () => {
      const strategyName = 'Needs-based project-oriented training'
      const pmtContext = {
        processes: 'ISO 26262',
        tools: 'DOORS'
      }
      const mockResponse = {
        learningObjectivesByStrategy: {
          'Needs-based project-oriented training': {}
        }
      }

      phase2Task3Api.addRecommendedStrategy.mockResolvedValue(mockResponse)

      const composable = usePhase2Task3(mockOrgId)
      await composable.addRecommendedStrategy(strategyName, pmtContext)

      expect(phase2Task3Api.addRecommendedStrategy).toHaveBeenCalledWith(mockOrgId, strategyName, pmtContext)
      expect(composable.learningObjectives.value).toEqual(mockResponse.learningObjectivesByStrategy)
    })
  })

  describe('exportObjectives', () => {
    it('should export objectives in specified format', async () => {
      const mockBlob = new Blob(['PDF content'], { type: 'application/pdf' })
      phase2Task3Api.exportLearningObjectives.mockResolvedValue(mockBlob)

      const composable = usePhase2Task3(mockOrgId)
      const result = await composable.exportObjectives('pdf')

      expect(phase2Task3Api.exportLearningObjectives).toHaveBeenCalledWith(mockOrgId, 'pdf', null, true)
      expect(result).toBe(mockBlob)
    })

    it('should export with strategy filter', async () => {
      const mockBlob = new Blob(['Excel content'])
      phase2Task3Api.exportLearningObjectives.mockResolvedValue(mockBlob)

      const composable = usePhase2Task3(mockOrgId)
      await composable.exportObjectives('excel', 'SE for managers')

      expect(phase2Task3Api.exportLearningObjectives).toHaveBeenCalledWith(mockOrgId, 'excel', 'SE for managers', true)
    })
  })

  describe('refreshData', () => {
    it('should refresh all data', async () => {
      const mockPrerequisites = { ready: true, pathway: 'ROLE_BASED' }
      const mockObjectives = { learningObjectivesByStrategy: {} }
      const mockPMT = { tools: 'DOORS' }

      phase2Task3Api.validatePrerequisites.mockResolvedValue(mockPrerequisites)
      phase2Task3Api.getLearningObjectives.mockResolvedValue(mockObjectives)
      phase2Task3Api.getPMTContext.mockResolvedValue(mockPMT)

      const composable = usePhase2Task3(mockOrgId)
      await composable.refreshData()

      expect(phase2Task3Api.validatePrerequisites).toHaveBeenCalled()
      expect(phase2Task3Api.getLearningObjectives).toHaveBeenCalled()
      expect(phase2Task3Api.getPMTContext).toHaveBeenCalled()
    })
  })

  describe('Computed Properties', () => {
    it('should compute hasObjectives correctly', () => {
      const composable = usePhase2Task3(mockOrgId)

      expect(composable.hasObjectives.value).toBe(false)

      composable.learningObjectives.value = {
        'SE for managers': {}
      }

      expect(composable.hasObjectives.value).toBe(true)
    })

    it('should compute isReadyToGenerate correctly', () => {
      const composable = usePhase2Task3(mockOrgId)

      expect(composable.isReadyToGenerate.value).toBe(false)

      composable.prerequisites.value = {
        readyToGenerate: true
      }

      expect(composable.isReadyToGenerate.value).toBe(true)
    })

    it('should compute needsPMT correctly', () => {
      const composable = usePhase2Task3(mockOrgId)

      composable.prerequisites.value = {
        needsPMT: true
      }

      expect(composable.needsPMT.value).toBe(true)
    })

    it('should compute hasPMT correctly', () => {
      const composable = usePhase2Task3(mockOrgId)

      composable.prerequisites.value = {
        hasPMT: true
      }

      expect(composable.hasPMT.value).toBe(true)
    })
  })
})
