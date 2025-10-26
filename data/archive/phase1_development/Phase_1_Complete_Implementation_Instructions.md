# SE-QPT Phase 1: Complete Implementation Instructions for Claude Code

## Project Context
Refactor the SE-QPT tool to implement the new 4-phase structure, starting with Phase 1 "Prepare SE Training" which consists of three sequential tasks.

## Phase 1 Architecture Overview

```
Phase 1: Prepare SE Training
├── Task 1: Assess SE Maturity Level
├── Task 2: Identify SE Roles
└── Task 3: Select SE Training Strategy
    └── Deliverables: SE Maturity Report, Roles List, Training Strategy
```

## Implementation Instructions

### STEP 1: Update Project Structure

```bash
# Create new folder structure
/src/phases/phase1/
  ├── task1-maturity/
  │   ├── MaturityAssessment.jsx
  │   ├── MaturityCalculator.js
  │   └── MaturityVisualization.jsx
  ├── task2-roles/
  │   ├── RoleIdentification.jsx
  │   ├── StandardRoles.jsx
  │   ├── TaskBasedMapping.jsx
  │   └── TargetGroupSize.jsx
  ├── task3-strategy/
  │   ├── StrategySelection.jsx
  │   ├── StrategyEngine.js
  │   ├── DecisionTree.jsx
  │   └── ProConComparison.jsx
  ├── review/
  │   └── Phase1Review.jsx
  └── Phase1Controller.jsx
```

### STEP 2: Implement Task 1 - Maturity Assessment

**File: `MaturityAssessment.jsx`**
```javascript
// Implement 4-question maturity assessment with improved algorithm
import { ImprovedMaturityCalculator } from './MaturityCalculator';

const MaturityAssessment = () => {
  const questions = [
    {
      id: 'rolloutScope',
      question: 'What is the current scope of Systems Engineering deployment?',
      options: ['Not Available', 'Individual Area', 'Development Area', 'Company Wide', 'Value Chain'],
      values: [0, 1, 2, 3, 4]
    },
    {
      id: 'seRolesProcesses',
      question: 'How mature are your SE processes and role definitions?',
      options: ['Not Available', 'Ad hoc', 'Individually Controlled', 'Defined', 'Quantitative', 'Optimized'],
      values: [0, 1, 2, 3, 4, 5]
    },
    {
      id: 'seMindset',
      question: 'How well is the SE mindset embedded in your culture?',
      options: ['Not Available', 'Individual', 'Fragmented', 'Established', 'Optimized'],
      values: [0, 1, 2, 3, 4]
    },
    {
      id: 'knowledgeBase',
      question: 'What is the state of your SE knowledge management?',
      options: ['Not Available', 'Individual', 'Fragmented', 'Established', 'Optimized'],
      values: [0, 1, 2, 3, 4]
    }
  ];
  
  // Render questionnaire with progress indicator
  // Calculate maturity using improved algorithm with balance penalty
  // Display spider chart for balance visualization
};
```

**File: `MaturityCalculator.js`**
```javascript
class ImprovedMaturityCalculator {
  static weights = {
    rolloutScope: 0.20,
    seRolesProcesses: 0.35,
    seMindset: 0.25,
    knowledgeBase: 0.20
  };
  
  calculate(answers) {
    // 1. Normalize values to 0-1 scale
    const normalized = this.normalize(answers);
    
    // 2. Calculate weighted score (0-100)
    const rawScore = this.calculateWeightedScore(normalized) * 100;
    
    // 3. Calculate balance penalty
    const penalty = this.calculateBalancePenalty(normalized);
    
    // 4. Apply thresholds
    const finalScore = this.applyThresholds(rawScore - penalty, normalized);
    
    // 5. Determine maturity level and profile
    return {
      finalScore: finalScore.toFixed(1),
      maturityLevel: this.getMaturityLevel(finalScore),
      balanceScore: this.getBalanceScore(normalized),
      profileType: this.getProfileType(normalized),
      fieldScores: this.getFieldScores(normalized),
      strategyInputs: {
        seProcessesValue: answers.seRolesProcesses,
        rolloutScopeValue: answers.rolloutScope
      }
    };
  }
}
```

### STEP 3: Implement Task 2 - Role Identification

**File: `RoleIdentification.jsx`**
```javascript
import { SE_ROLE_CLUSTERS } from './roleData';

const RoleIdentification = ({ maturityData }) => {
  const [pathway, setPathway] = useState(null);
  const [identifiedRoles, setIdentifiedRoles] = useState([]);
  const [targetGroupSize, setTargetGroupSize] = useState(null);
  
  useEffect(() => {
    // Determine pathway based on seRolesProcesses value
    const pathway = maturityData.strategyInputs.seProcessesValue >= 3 
      ? 'STANDARD' 
      : 'TASK_BASED';
    setPathway(pathway);
  }, [maturityData]);
  
  return (
    <div className="role-identification">
      <h2>Task 2: Identify SE Roles</h2>
      
      {pathway === 'STANDARD' ? (
        <StandardRoleSelection 
          roles={SE_ROLE_CLUSTERS}
          onSelect={setIdentifiedRoles}
        />
      ) : (
        <TaskBasedMapping 
          onComplete={setIdentifiedRoles}
        />
      )}
      
      {identifiedRoles.length > 0 && (
        <TargetGroupSizeSelection 
          onSelect={setTargetGroupSize}
          onComplete={() => proceedToTask3()}
        />
      )}
    </div>
  );
};
```

**File: `TaskBasedMapping.jsx`**
```javascript
const TaskBasedMapping = ({ onComplete }) => {
  const [jobProfiles, setJobProfiles] = useState([]);
  const [mappingResults, setMappingResults] = useState(null);
  
  const performMapping = async () => {
    // For each job profile:
    // 1. Extract tasks using AI
    // 2. Map to ISO 15288 processes
    // 3. Match to SE role clusters
    // 4. Consolidate duplicates
    
    const results = await mapJobProfilesToRoles(jobProfiles);
    setMappingResults(results);
  };
  
  return (
    <div className="task-based-mapping">
      <JobProfileInput 
        profiles={jobProfiles}
        onAdd={addProfile}
        onRemove={removeProfile}
      />
      
      {jobProfiles.length > 0 && (
        <button onClick={performMapping}>
          Map to SE Roles
        </button>
      )}
      
      {mappingResults && (
        <MappingConfirmation 
          results={mappingResults}
          onConfirm={onComplete}
        />
      )}
    </div>
  );
};
```

### STEP 4: Implement Task 3 - Strategy Selection

**File: `StrategyEngine.js`**
```javascript
class StrategySelectionEngine {
  constructor(maturityData, targetGroupSize) {
    this.maturity = maturityData;
    this.groupSize = targetGroupSize;
    this.strategies = [];
    this.decisionPath = [];
  }
  
  selectStrategies() {
    // Step 1: Evaluate Train-the-Trainer need
    if (this.groupSize.value >= 100) {
      this.addTrainTheTrainer();
    }
    
    // Step 2: Main strategy based on maturity
    const seProcesses = this.maturity.strategyInputs.seProcessesValue;
    const rolloutScope = this.maturity.strategyInputs.rolloutScopeValue;
    
    if (seProcesses <= 1) {
      // Low maturity: SE for Managers + Secondary
      this.addPrimaryStrategy('se_for_managers');
      this.requireSecondarySelection = true;
    } else if (rolloutScope <= 1) {
      // High maturity, narrow rollout
      this.addPrimaryStrategy('needs_based_project');
    } else {
      // High maturity, broad rollout
      this.addPrimaryStrategy('continuous_support');
    }
    
    return {
      strategies: this.strategies,
      decisionPath: this.decisionPath,
      requiresUserChoice: this.requireSecondarySelection
    };
  }
}
```

**File: `StrategySelection.jsx`**
```javascript
const StrategySelection = ({ maturityData, targetGroupSize, identifiedRoles }) => {
  const [selectedStrategies, setSelectedStrategies] = useState([]);
  const [showProCon, setShowProCon] = useState(false);
  
  useEffect(() => {
    const engine = new StrategySelectionEngine(maturityData, targetGroupSize);
    const results = engine.selectStrategies();
    
    setSelectedStrategies(results.strategies);
    setShowProCon(results.requiresUserChoice);
  }, [maturityData, targetGroupSize]);
  
  return (
    <div className="strategy-selection">
      <DecisionTreeVisualization 
        maturityData={maturityData}
        path={selectedStrategies}
      />
      
      <StrategyCards 
        strategies={SE_TRAINING_STRATEGIES}
        selected={selectedStrategies}
      />
      
      {showProCon && (
        <ProConComparison 
          strategies={['common_understanding', 'orientation_pilot', 'certification']}
          onSelect={handleSecondarySelection}
        />
      )}
      
      <StrategySummary 
        strategies={selectedStrategies}
        targetGroup={targetGroupSize}
      />
    </div>
  );
};
```

### STEP 5: Create Phase Controller

**File: `Phase1Controller.jsx`**
```javascript
const Phase1Controller = () => {
  const [currentTask, setCurrentTask] = useState(1);
  const [phaseData, setPhaseData] = useState({
    maturity: null,
    roles: null,
    targetGroupSize: null,
    strategies: null
  });
  
  const taskComponents = {
    1: <MaturityAssessment onComplete={handleMaturityComplete} />,
    2: <RoleIdentification 
         maturityData={phaseData.maturity}
         onComplete={handleRolesComplete} 
       />,
    3: <StrategySelection 
         maturityData={phaseData.maturity}
         targetGroupSize={phaseData.targetGroupSize}
         identifiedRoles={phaseData.roles}
         onComplete={handleStrategyComplete}
       />,
    4: <Phase1Review 
         data={phaseData}
         onConfirm={completePhase1}
       />
  };
  
  return (
    <div className="phase1-container">
      <PhaseProgress currentTask={currentTask} totalTasks={3} />
      <TaskNavigation 
        current={currentTask}
        onNavigate={setCurrentTask}
        completedTasks={getCompletedTasks()}
      />
      {taskComponents[currentTask]}
    </div>
  );
};
```

### STEP 6: Update Database Schema

```sql
-- Phase 1 Tables with proper relationships
CREATE TABLE phase1_maturity (
  id SERIAL PRIMARY KEY,
  org_id INTEGER REFERENCES organizations(id),
  rollout_scope INTEGER CHECK (rollout_scope BETWEEN 0 AND 4),
  se_processes INTEGER CHECK (se_processes BETWEEN 0 AND 5),
  se_mindset INTEGER CHECK (se_mindset BETWEEN 0 AND 4),
  knowledge_base INTEGER CHECK (knowledge_base BETWEEN 0 AND 4),
  final_score DECIMAL(4,1),
  maturity_level INTEGER CHECK (maturity_level BETWEEN 1 AND 5),
  balance_score DECIMAL(4,1),
  profile_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE phase1_roles (
  id SERIAL PRIMARY KEY,
  maturity_id INTEGER REFERENCES phase1_maturity(id),
  standard_role_id INTEGER,
  org_role_name VARCHAR(100),
  identification_method VARCHAR(20),
  confidence_score DECIMAL(3,1),
  participating BOOLEAN DEFAULT true
);

CREATE TABLE phase1_target_group (
  id SERIAL PRIMARY KEY,
  maturity_id INTEGER REFERENCES phase1_maturity(id),
  size_range VARCHAR(20),
  size_category VARCHAR(20),
  estimated_count INTEGER
);

CREATE TABLE phase1_strategies (
  id SERIAL PRIMARY KEY,
  maturity_id INTEGER REFERENCES phase1_maturity(id),
  strategy_type VARCHAR(50),
  priority VARCHAR(20),
  reason TEXT,
  user_selected BOOLEAN DEFAULT false
);
```

### STEP 7: Create API Endpoints

```javascript
// API routes for Phase 1
const phase1Routes = {
  // Maturity Assessment
  'POST /api/phase1/maturity': saveMaturityAssessment,
  'GET /api/phase1/maturity/:orgId': getMaturityAssessment,
  
  // Role Identification
  'GET /api/phase1/roles/standard': getStandardRoleClusters,
  'POST /api/phase1/roles/map-tasks': mapTasksToRoles,
  'POST /api/phase1/roles/confirm': confirmRoleMapping,
  
  // Target Group
  'POST /api/phase1/target-group': saveTargetGroupSize,
  
  // Strategy Selection
  'POST /api/phase1/strategies/calculate': calculateStrategies,
  'GET /api/phase1/strategies/options': getStrategyOptions,
  'POST /api/phase1/strategies/confirm': confirmStrategies,
  
  // Phase Completion
  'GET /api/phase1/summary/:orgId': getPhase1Summary,
  'POST /api/phase1/complete': completePhase1
};
```

### STEP 8: Implement State Management

```javascript
// Redux/Context state structure
const phase1State = {
  currentTask: 1,
  maturity: {
    responses: {},
    results: null,
    completed: false
  },
  roles: {
    pathway: null, // 'STANDARD' or 'TASK_BASED'
    identifiedRoles: [],
    targetGroupSize: null,
    completed: false
  },
  strategies: {
    recommended: [],
    selected: [],
    decisionPath: [],
    completed: false
  },
  validation: {
    canProceed: false,
    warnings: [],
    errors: []
  }
};
```

### STEP 9: Add Validation Logic

```javascript
const Phase1Validator = {
  validateTask1: (maturityData) => {
    // All 4 questions must be answered
    // Check for critical imbalance
    // Validate score calculation
  },
  
  validateTask2: (roles, targetGroup) => {
    // At least 1 role selected
    // Target group size selected
    // Confidence scores acceptable (>65% for task-based)
  },
  
  validateTask3: (strategies) => {
    // At least 1 strategy selected
    // Secondary strategy selected if required
    // Strategy compatible with group size
  },
  
  validatePhase1Complete: (allData) => {
    // All tasks completed
    // Data consistency checks
    // Ready for Phase 2 handoff
  }
};
```

### STEP 10: Testing Checklist

```javascript
// Test scenarios to implement
const testScenarios = [
  {
    name: 'Low Maturity Organization',
    input: { seProcesses: 1, rollout: 0, mindset: 1, knowledge: 0 },
    expected: {
      pathway: 'TASK_BASED',
      primaryStrategy: 'se_for_managers',
      requiresSecondary: true
    }
  },
  {
    name: 'High Maturity Narrow Rollout',
    input: { seProcesses: 4, rollout: 1, mindset: 3, knowledge: 3 },
    expected: {
      pathway: 'STANDARD',
      primaryStrategy: 'needs_based_project',
      requiresSecondary: false
    }
  },
  {
    name: 'Large Organization',
    input: { targetGroupSize: 1000 },
    expected: {
      includesTrainTheTrainer: true
    }
  }
];
```

## Critical Implementation Notes

1. **Data Flow**: Ensure proper data passing between tasks using Phase1Controller
2. **Validation**: Implement guards to prevent proceeding without required data
3. **AI Integration**: Task-based role mapping requires LLM integration for task extraction
4. **Persistence**: Save progress after each task completion
5. **Error Handling**: Graceful degradation if AI services unavailable
6. **Accessibility**: Ensure all interactive elements are keyboard navigable
7. **Mobile Responsiveness**: Test all components on mobile devices

## Migration from Old Structure

```javascript
// Migration utility
const migrateFromOldStructure = (oldData) => {
  return {
    // Map old 12-question assessment to new 4-question format
    rolloutScope: mapOldToNewRollout(oldData),
    seProcesses: mapOldToNewProcesses(oldData),
    seMindset: mapOldToNewMindset(oldData),
    knowledgeBase: mapOldToNewKnowledge(oldData)
  };
};
```

## Next Steps for Claude Code

1. Start with Phase1Controller.jsx as the main orchestrator
2. Implement each task sequentially (Maturity → Roles → Strategy)
3. Ensure data persistence between tasks
4. Add comprehensive error handling
5. Implement the review screen with edit capabilities
6. Test the complete flow with various organization profiles
7. Add export functionality for Phase 1 deliverables

## Resources to Reference

- `Qualifizierungsmodule_Qualifizierungspläne_v4 enUS.xlsx` for competency matrices
- Derik's thesis for task-based role mapping algorithm
- Sachin's thesis for learning format parameters (Phase 3 reference)

Use this comprehensive guide to systematically refactor the SE-QPT Phase 1 implementation.