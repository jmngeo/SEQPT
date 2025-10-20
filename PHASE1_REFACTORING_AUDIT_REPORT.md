# Phase 1 Refactoring Audit Report
**Generated**: 2025-10-18
**Scope**: Complete analysis of current Phase 1 implementation vs. new 4-phase refactoring requirements

## Executive Summary

The current Phase 1 implementation contains a **BRETZ-based maturity assessment** and an **archetype selection** questionnaire that **MUST BE COMPLETELY DISCARDED** and replaced with the new 3-task structure defined in the refactoring specifications.

**Critical Finding**: The existing implementation is fundamentally incompatible with the new design and requires a complete rebuild.

---

## Part 1: Current Implementation Analysis

### 1.1 Existing Phase 1 Components (TO BE DISCARDED)

#### Frontend Component: `PhaseOne.vue`
**Location**: `src/frontend/src/views/phases/PhaseOne.vue`
**Size**: 1,262 lines
**Status**: ❌ **DISCARD COMPLETELY**

**Current Structure**:
```
Steps:
├── Step 0: Organization Information (hidden, pre-filled)
├── Step 1: Maturity Assessment (BRETZ model - 12 questions)
├── Step 2: Archetype Selection (Dual-path decision tree)
└── Step 3: Review & Confirm
```

**What This Component Does**:
1. **Organization Info**: Pre-fills from user registration
2. **Maturity Assessment**: Uses `QuestionnaireComponent` with questionnaire ID=1
3. **Archetype Selection**: Uses `QuestionnaireComponent` with questionnaire ID=2
4. **Archetype Computation**: Calls `/api/seqpt/phase1/archetype-selection` to compute archetype
5. **Review**: Displays maturity level (5-level scale) and selected archetype
6. **Completion**: Saves to database via `/api/organization/phase1-complete`

**Dual-Role Support**:
- Admin view: Complete full workflow
- Employee view: Read-only organizational results (`OrganizationResultsCard`)

#### Questionnaire Files (TO BE DISCARDED)

**1. Maturity Assessment**
**Location**: `data/source/questionnaires/phase1/maturity_assessment.json`
**Status**: ❌ **DISCARD**

**Structure**:
- Based on BRETZ model
- 4 sections: Fundamentals, Organization, Process Capability, Infrastructure
- 12 questions total (MAT_01 to MAT_12)
- 5-point scale (0-4): Not available → Optimized
- Key questions:
  - `MAT_01`: SE mindset prevalence
  - `MAT_02`: SE knowledge management
  - `MAT_04`: SE processes definition (**routing trigger for archetype**)
  - `MAT_05`: SE rollout scope (**routing trigger for archetype**)

**Maturity Levels Calculated**:
- Initial (0-19%)
- Performed (20-39%)
- Managed (40-59%)
- Defined (60-79%)
- Optimizing (80-100%)

**2. Archetype Selection**
**Location**: `data/source/questionnaires/phase1/archetype_selection.json`
**Status**: ❌ **DISCARD**

**Structure**:
- Adaptive routing based on MAT_04 (SE processes maturity)
- **Low Maturity Path** (MAT_04 ≤ 1):
  - Primary: "SE for Managers" (automatic)
  - Secondary: User chooses via ARCH_01 (Apply pilot vs. Build awareness vs. Create experts)
- **High Maturity Path** (MAT_04 > 1):
  - Single selection based on MAT_05 (rollout scope)
  - Narrow rollout → "Needs-based Project-oriented Training"
  - Broad rollout → "Continuous Support"

**Archetypes Available**:
- Common Basic Understanding (A)
- Needs-based Project-oriented Training (B)
- Continuous Support (C)
- SE for Managers (D)
- Orientation in Pilot Project (from preference)

#### Backend API Endpoints (TO BE REVIEWED/MODIFIED)

**Current Endpoints**:
```
POST /api/seqpt/phase1/archetype-selection
  - Computes archetype based on maturity + preferences
  - Returns: archetype name, secondary, customization level, rationale

PUT /api/organization/phase1-complete
  - Saves maturity_score (percentage), selected_archetype
  - Updates organization table

GET /api/questionnaires/1 (maturity)
GET /api/questionnaires/2?mat_04={value} (archetype with filtering)
```

**Status**: ⚠️ **MODIFY** - Endpoints need to be updated for new 3-task structure

#### Supporting Components

**1. OrganizationResultsCard.vue**
**Location**: `src/frontend/src/components/phases/OrganizationResultsCard.vue`
**Status**: ⚠️ **REVIEW** - May be reusable for Task 3 review

**2. QuestionnaireComponent.vue**
**Location**: `src/frontend/src/components/common/QuestionnaireComponent.vue`
**Status**: ✅ **KEEP** - Generic questionnaire renderer (will be used for Task 1)

**3. Dashboard Phase Navigation**
**Location**: `src/frontend/src/views/Dashboard.vue` (lines 151-194)
**Status**: ⚠️ **UPDATE LABELS** - Phase titles/descriptions need updating

Current labels:
```javascript
Admin Phase 1: "Phase 1: Maturity Assessment & Archetype Selection"
Employee Phase 1: "Organization Assessment Results"
```

New labels should be:
```javascript
Admin Phase 1: "Phase 1: Prepare SE Training"
Employee Phase 1: "Organization Phase 1 Results"
```

---

## Part 2: What Must Be Discarded

### 2.1 Files to DELETE/ARCHIVE

**Questionnaire Files**:
```
❌ DELETE: data/source/questionnaires/phase1/maturity_assessment.json
❌ DELETE: data/source/questionnaires/phase1/archetype_selection.json
✅ ARCHIVE: data/source/questionnaires/phase1/maturity_assessment_backup_old.json (already archived)
✅ ARCHIVE: data/source/questionnaires/phase1/archetype_selection_backup_old.json (already archived)
```

**Reference Files to KEEP**:
```
✅ KEEP: data/source/questionnaires/phase1/seqpt_maturity_complete_reference_final.json
  → This is the NEW maturity assessment for Task 1 (6 dimensions)
```

### 2.2 Code to REMOVE from PhaseOne.vue

**All BRETZ-related code** (~lines 392-673):
- `calculatedMaturityLevel` computed property (5-level BRETZ scale)
- `selectedArchetype` computed property (A/B/C/D mapping)
- `getMaturityLevelDescription()` (BRETZ descriptions)
- `getMaturityPercentage()` (percentage calculation)
- `getArchetypeDescription()` (archetype descriptions)
- `getArchetypeCharacteristics()` (archetype characteristics)

**All archetype computation code** (~lines 574-626):
- `onArchetypeCompleted()` - Archetype computation API call
- Dual archetype display logic

**Template sections to REMOVE**:
- Lines 108-134: Old maturity assessment step
- Lines 136-161: Old archetype selection step
- Lines 164-327: Old review/confirm structure

### 2.3 Backend Routes to MODIFY/REMOVE

**Remove**:
```python
POST /api/seqpt/phase1/archetype-selection
  → Old archetype computation logic
```

**Keep but modify**:
```python
PUT /api/organization/phase1-complete
  → Needs to save:
     - maturity_level (new 6-dimension assessment)
     - identified_roles[] (Task 2)
     - selected_strategies[] (Task 3)
     - target_group_size (Task 2 output)
```

---

## Part 3: Missing Implementation (What Needs to Be Built)

### 3.1 Task 1: Assess SE Maturity Level

**Status**: ⚠️ **PARTIALLY EXISTS** - New questionnaire defined, needs frontend integration

**What Exists**:
- ✅ New maturity questionnaire: `seqpt_maturity_complete_reference_final.json`
- ✅ 6 dimensions defined (vs. old 4 sections)

**What's Missing**:
- ❌ Frontend integration with new questionnaire structure
- ❌ New maturity calculation algorithm (6 dimensions vs. BRETZ RMS)
- ❌ New maturity level display (need to define levels for 0-5 scale per dimension)

**New Dimensions to Implement**:
1. Rollout Scope (SCOPE)
2. SE Mindset (MINDSET)
3. SE Roles & Processes (PROCESSES) ← **Critical for Task 2 routing**
4. Knowledge Base (KNOWLEDGE)
5. Tools & Infrastructure (TOOLS)
6. Management Support (MANAGEMENT)

**Each dimension scored 0-5**:
- 0: Not Available
- 1: Ad hoc / Undefined
- 2: Individually Controlled
- 3: Defined and Established
- 4: Quantitatively Predictable
- 5: Optimized

### 3.2 Task 2: Identify SE Roles

**Status**: ❌ **COMPLETELY MISSING** - No implementation exists

**What Needs to Be Built**:

#### 2.1 Decision Routing Logic
```javascript
const determineRoleIdentificationPathway = (seProcessesValue) => {
  const MATURITY_THRESHOLD = 3 // "Defined and Established"

  if (seProcessesValue >= MATURITY_THRESHOLD) {
    return 'STANDARD_ROLES_PATHWAY' // High maturity
  } else {
    return 'TASK_BASED_PATHWAY' // Low maturity
  }
}
```

**Input**: `seProcessesValue` from Task 1 maturity assessment (PROCESSES dimension)

#### 2.2 Pathway A: Standard Roles Selection (High Maturity)

**Missing Component**: `StandardRoleSelection.vue`

**Functionality**:
- Display 14 SE role clusters with checkboxes
- Each role shows:
  - Standard name (e.g., "Project Manager")
  - Description
  - Input field for organization-specific name adaptation
- Selection counter: "X / 14 roles selected"
- Save to `organization_roles` table

**Data Structure**:
```javascript
const SE_ROLE_CLUSTERS = [
  { id: 1, name: "Customer", description: "..." },
  { id: 2, name: "Customer Representative", description: "..." },
  // ... 12 more roles
]
```

#### 2.3 Pathway B: Task-Based Role Mapping (Low Maturity)

**Missing Components**:
- `JobProfileCollection.vue` - Collect multiple job profiles
- `TaskBasedRoleMapping.js` - AI-powered task extraction
- `RoleConfirmation.vue` - Confirm AI-suggested role mappings

**Workflow**:
1. **Input**: User adds multiple job profiles (title, responsibilities, activities)
2. **AI Processing**:
   - Extract tasks from job descriptions
   - Map tasks to ISO 15288 processes (30 processes)
   - Calculate role similarity using Role-Process matrix
   - Suggest matching SE roles from 14 clusters
3. **Confirmation**: User reviews and confirms mappings
4. **Consolidation**: Merge duplicate role mappings

**Required AI Endpoints**:
```
POST /api/ai/extract-tasks
POST /api/ai/map-to-iso-processes
POST /api/ai/calculate-role-similarity
```

#### 2.4 Target Group Size Collection

**Missing Component**: `TargetGroupSizeAssessment.vue`

**Functionality**:
- Radio button selection:
  - < 20 people (Small)
  - 20-100 people (Medium)
  - 100-500 people (Large)
  - 500-1500 people (Very Large)
  - > 1500 people (Enterprise)
- Store in `training_target_group` table
- **Critical**: Used in Task 3 to determine Train-the-Trainer strategy

#### 2.5 Database Schema (Missing Tables)

**Required Tables**:
```sql
CREATE TABLE organization_roles (
  id INTEGER PRIMARY KEY,
  org_id INTEGER FOREIGN KEY,
  assessment_id INTEGER FOREIGN KEY,
  standard_role_id INTEGER, -- 1-14
  standard_role_name VARCHAR(100),
  organization_role_name VARCHAR(100),
  identification_method VARCHAR(20), -- 'STANDARD' or 'TASK_BASED'
  confidence_score DECIMAL(3,1), -- For task-based only
  created_date TIMESTAMP
);

CREATE TABLE role_task_mappings (
  id INTEGER PRIMARY KEY,
  org_role_id INTEGER FOREIGN KEY,
  task_description TEXT,
  involvement_level VARCHAR(20), -- 'RESPONSIBLE', 'SUPPORTING', 'DESIGNING'
  iso_process VARCHAR(100),
  ai_confidence DECIMAL(3,1)
);

CREATE TABLE training_target_group (
  id INTEGER PRIMARY KEY,
  org_id INTEGER FOREIGN KEY,
  assessment_id INTEGER FOREIGN KEY,
  size_range VARCHAR(20), -- '< 20', '20-100', etc.
  size_category VARCHAR(20), -- 'SMALL', 'MEDIUM', etc.
  estimated_count INTEGER,
  created_date TIMESTAMP
);
```

### 3.3 Task 3: Select SE Training Strategy

**Status**: ❌ **COMPLETELY MISSING** - No implementation exists

**What Needs to Be Built**:

#### 3.1 Strategy Data Structure

**Missing File**: `src/frontend/src/data/trainingStrategies.js`

**7 Strategies to Define**:
1. SE for Managers (FOUNDATIONAL)
2. Common Basic Understanding (AWARENESS)
3. Orientation in Pilot Project (APPLICATION)
4. Certification (SPECIALIZATION)
5. Continuous Support (SUSTAINMENT)
6. Needs-based Project-oriented Training (TARGETED)
7. Train the SE-Trainer (MULTIPLIER)

Each strategy needs:
- Name, category, description
- Qualification level (Understanding, Application, Mastery)
- Target audience
- Group size (min, max, optimal)
- Duration, benefits, drawbacks
- Implementation format

#### 3.2 Decision Tree Engine

**Missing Component**: `StrategySelectionEngine.js`

**Algorithm**:
```javascript
class StrategySelectionEngine {
  constructor(maturityData, targetGroupSize) {
    this.maturityData = maturityData
    this.targetGroupSize = targetGroupSize
    this.selectedStrategies = []
  }

  selectStrategies() {
    // Step 1: Train-the-Trainer decision
    if (targetGroupSize >= 100) {
      this.selectedStrategies.push({
        strategy: 'train_the_trainer',
        priority: 'SUPPLEMENTARY'
      })
    }

    // Step 2: Main strategy
    if (seRolesProcesses <= 1) {
      // Low maturity → "SE for Managers" + user choice
      this.selectedStrategies.push({
        strategy: 'se_for_managers',
        priority: 'PRIMARY'
      })
      // Show pro-con comparison for secondary
    } else {
      // High maturity
      if (rolloutScope <= 1) {
        this.selectedStrategies.push({
          strategy: 'needs_based_project',
          priority: 'PRIMARY'
        })
      } else {
        this.selectedStrategies.push({
          strategy: 'continuous_support',
          priority: 'PRIMARY'
        })
      }
    }

    return this.selectedStrategies
  }
}
```

#### 3.3 UI Components

**Missing Components**:

1. **StrategySelectionPage.vue** - Main container
   - Decision visualization
   - Strategy recommendation engine integration
   - Reasoning display
   - Strategy cards grid

2. **StrategyCard.vue** - Individual strategy display
   - Checkbox selection
   - Strategy details (target group, duration, benefits)
   - Recommended badge
   - "View Details" button

3. **ProConComparison.vue** - For low maturity secondary selection
   - Side-by-side comparison of 3 options:
     - Common Basic Understanding
     - Orientation in Pilot Project
     - Certification
   - Pros/cons lists
   - Selection buttons

4. **DecisionTreeVisualization.vue** - Visual decision tree
   - SVG-based tree diagram
   - Highlight selected path
   - Show reasoning at each node

5. **Phase1ReviewConfirm.vue** - Final review page
   - Organization overview
   - Maturity results (6 dimensions)
   - Target group size
   - Identified roles list
   - Selected strategies summary
   - "Confirm & Proceed to Phase 2" button

#### 3.4 Database Schema

**Required Tables**:
```sql
CREATE TABLE strategy_selection (
  id INTEGER PRIMARY KEY,
  org_id INTEGER FOREIGN KEY,
  assessment_id INTEGER FOREIGN KEY,
  primary_strategy VARCHAR(50),
  secondary_strategy VARCHAR(50),
  has_train_trainer BOOLEAN,
  decision_based_on_processes INTEGER, -- MAT_04 value
  decision_based_on_rollout INTEGER, -- MAT_05 value
  user_preference VARCHAR(50),
  decision_path JSON,
  created_date TIMESTAMP
);

CREATE TABLE strategy_customization (
  id INTEGER PRIMARY KEY,
  selection_id INTEGER FOREIGN KEY,
  strategy_id VARCHAR(50),
  custom_duration VARCHAR(100),
  custom_group_size VARCHAR(100),
  implementation_notes TEXT
);
```

---

## Part 4: Dependencies and Integration Points

### 4.1 Integration with Existing Components

**QuestionnaireComponent.vue**: ✅ REUSE
- Already supports dynamic questionnaire rendering
- Works with new maturity questionnaire format
- No changes needed

**usePhaseProgression.js**: ⚠️ UPDATE
- Current logic checks Phase 1 completion by checking `maturity_score` and `selected_archetype`
- **Needs update** to check for:
  - Maturity assessment completed
  - Roles identified (count > 0)
  - Strategies selected (count > 0)

**Dashboard.vue**: ⚠️ UPDATE LABELS
- Line 147: Change "Admin Complete Workflow" → Keep as is
- Lines 401-408: Update phase title and description
  - Current: "Phase 1: Maturity Assessment & Archetype Selection"
  - New: "Phase 1: Prepare SE Training"
  - Description: "Assess maturity, identify roles, select strategies"

### 4.2 Backend API Requirements

**New Endpoints Needed**:
```
# Task 1: Maturity Assessment
GET /api/questionnaires/phase1/maturity  → Return new 6-dimension questionnaire
POST /api/phase1/maturity                → Save maturity responses

# Task 2: Role Identification
GET /api/roles/standard-clusters         → Return 14 SE roles
POST /api/roles/identify                 → Save selected/mapped roles
POST /api/roles/map-tasks                → AI task-to-role mapping
POST /api/roles/target-group-size        → Save target group size

# Task 3: Strategy Selection
GET /api/strategies/definitions          → Return 7 strategies
POST /api/strategies/calculate           → Run decision tree
POST /api/strategies/select              → Save strategy selection

# Phase 1 Completion
POST /api/phase1/complete                → Save all Phase 1 data
GET /api/phase1/summary/{org_id}         → Get Phase 1 results
```

**Modify Existing Endpoints**:
```
PUT /api/organization/phase1-complete
  OLD: { maturity_score, selected_archetype }
  NEW: {
    maturity_dimensions: { scope, mindset, processes, knowledge, tools, management },
    identified_roles: [...],
    target_group_size: { range, category, count },
    selected_strategies: { primary, secondary, has_trainer }
  }
```

### 4.3 Database Migration Required

**Organization Table Updates**:
```sql
ALTER TABLE organizations DROP COLUMN maturity_score;  -- Was 0-100 percentage
ALTER TABLE organizations DROP COLUMN selected_archetype;  -- Was A/B/C/D

ALTER TABLE organizations ADD COLUMN maturity_scope INTEGER;  -- 0-5
ALTER TABLE organizations ADD COLUMN maturity_mindset INTEGER;  -- 0-5
ALTER TABLE organizations ADD COLUMN maturity_processes INTEGER;  -- 0-5 (critical!)
ALTER TABLE organizations ADD COLUMN maturity_knowledge INTEGER;  -- 0-5
ALTER TABLE organizations ADD COLUMN maturity_tools INTEGER;  -- 0-5
ALTER TABLE organizations ADD COLUMN maturity_management INTEGER;  -- 0-5
ALTER TABLE organizations ADD COLUMN target_group_size VARCHAR(20);  -- '100-500'
ALTER TABLE organizations ADD COLUMN primary_strategy VARCHAR(50);
ALTER TABLE organizations ADD COLUMN secondary_strategy VARCHAR(50);
ALTER TABLE organizations ADD COLUMN has_train_trainer BOOLEAN;
```

**New Tables**:
- `organization_roles` (detailed role mappings)
- `role_task_mappings` (task-based pathway data)
- `training_target_group` (target group details)
- `strategy_selection` (strategy decision data)
- `strategy_customization` (strategy adaptations)

---

## Part 5: Refactoring Recommendations

### 5.1 Recommended Approach: Clean Slate Rebuild

**Why Not Incremental Updates?**
1. The new structure is fundamentally different (1+1 tasks → 3 tasks)
2. Maturity model changed (4 sections → 6 dimensions)
3. Archetype selection completely replaced by strategy selection
4. Decision tree logic is incompatible

**Recommended Strategy**:
1. ✅ **Archive** current `PhaseOne.vue` → `PhaseOne_old.vue`
2. ✅ **Archive** old questionnaires (already done)
3. ✅ **Create new** `PhaseOne.vue` from scratch
4. ✅ **Keep** reusable components: `QuestionnaireComponent.vue`
5. ✅ **Build** new components incrementally (Task 1 → Task 2 → Task 3)

### 5.2 Implementation Sequence

**Phase 1 Refactoring Roadmap**:

#### Week 1: Task 1 - Maturity Assessment
- [ ] Create new maturity questionnaire backend endpoint
- [ ] Update frontend to use new 6-dimension questionnaire
- [ ] Implement new maturity calculation logic
- [ ] Create maturity results display component
- [ ] Test maturity assessment flow

#### Week 2: Task 2 - Role Identification
- [ ] Build 14 SE role clusters data structure
- [ ] Create Standard Roles Selection component (Pathway A)
- [ ] Create Job Profile Collection component (Pathway B)
- [ ] Implement AI task-to-role mapping backend
- [ ] Create Role Confirmation component
- [ ] Build Target Group Size component
- [ ] Create database tables (`organization_roles`, `training_target_group`)
- [ ] Test both pathways

#### Week 3: Task 3 - Strategy Selection
- [ ] Define 7 SE training strategies data structure
- [ ] Build Strategy Selection Engine (decision tree)
- [ ] Create Strategy Card component
- [ ] Create Pro-Con Comparison component
- [ ] Create Decision Tree Visualization component
- [ ] Build strategy selection backend endpoints
- [ ] Create database tables (`strategy_selection`)
- [ ] Test strategy selection logic

#### Week 4: Integration & Review
- [ ] Create Phase 1 Review & Confirm page
- [ ] Integrate all 3 tasks into PhaseOne.vue workflow
- [ ] Update Phase 1 completion endpoint
- [ ] Update Dashboard phase labels
- [ ] Update phase progression logic
- [ ] Database migration script
- [ ] End-to-end testing (admin + employee flows)
- [ ] User acceptance testing

### 5.3 File Structure for New Implementation

**Recommended structure**:
```
src/frontend/src/
├── views/phases/
│   ├── PhaseOne.vue (NEW - main container)
│   └── PhaseOne_old.vue (ARCHIVED)
├── components/phase1/
│   ├── task1/
│   │   ├── MaturityAssessment.vue
│   │   └── MaturityResults.vue
│   ├── task2/
│   │   ├── RoleIdentificationRouter.vue (decides pathway)
│   │   ├── StandardRoleSelection.vue (Pathway A)
│   │   ├── JobProfileCollection.vue (Pathway B)
│   │   ├── TaskBasedRoleMapping.vue (Pathway B)
│   │   ├── RoleConfirmation.vue (Pathway B)
│   │   └── TargetGroupSizeInput.vue
│   ├── task3/
│   │   ├── StrategySelectionPage.vue
│   │   ├── StrategyCard.vue
│   │   ├── ProConComparison.vue
│   │   ├── DecisionTreeVisualization.vue
│   │   └── StrategyEngine.js
│   └── review/
│       └── Phase1ReviewConfirm.vue
├── data/
│   ├── seRoleClusters.js (14 roles)
│   └── trainingStrategies.js (7 strategies)
└── composables/
    └── usePhase1Workflow.js (state management)
```

---

## Part 6: Risk Assessment

### 6.1 High-Risk Items

**1. Database Migration**
- **Risk**: Existing organizations have `maturity_score` and `selected_archetype` data
- **Mitigation**:
  - Create migration script to convert old data to new format
  - Keep old columns temporarily for rollback
  - Provide admin UI to re-run Phase 1 if needed

**2. Employee View Breaking**
- **Risk**: Employees viewing org results will see blank data after migration
- **Mitigation**:
  - Add migration flag to organization table
  - Show "Phase 1 Under Review" message if migration incomplete
  - Admins must re-complete Phase 1 after refactoring

**3. AI Integration for Task-Based Pathway**
- **Risk**: AI task extraction may be unreliable or slow
- **Mitigation**:
  - Build fallback manual role selection
  - Cache AI responses
  - Set confidence threshold (65%+) for auto-suggestions

### 6.2 Timeline Risks

**Estimated Effort**: 3-4 weeks (1 developer full-time)

**Critical Dependencies**:
- AI integration for Task 2 (external API or local LLM)
- Database migration coordination
- QA testing resources

---

## Part 7: Next Steps

### 7.1 Immediate Actions Required

1. **Decision Checkpoint**: Confirm refactoring approach with stakeholders
2. **Backup Current System**: Full database + code backup before any changes
3. **Setup Development Branch**: `feature/phase1-refactoring`
4. **Archive Old Code**: Move old files to `phase1_legacy/` folder

### 7.2 Questions for Resolution

**Before Starting Implementation**:

1. **AI Integration**: Which AI service for task-to-role mapping?
   - OpenAI GPT-4?
   - Local LLM (Llama, Mistral)?
   - Rule-based fallback only?

2. **Migration Strategy**: How to handle existing Phase 1 data?
   - Force all organizations to re-complete Phase 1?
   - Attempt automated data conversion?
   - Keep old data read-only, new data separate?

3. **ISO 15288 Process Database**: Where is the master list of 30 ISO processes?
   - Needs to be loaded for task-to-process mapping

4. **Role-Process Matrix**: Do we have the matrix data for role similarity calculation?
   - Required for task-based pathway (Pathway B)

5. **Timeline Constraints**: What's the target completion date?
   - Affects whether we implement all features or MVP first

---

## Part 8: Summary of Findings

### What EXISTS and Must Be DISCARDED
✅ **Exists but DELETE**:
- BRETZ maturity assessment (12 questions, 4 sections)
- Dual-path archetype selection (A/B/C/D mapping)
- PhaseOne.vue with 4-step workflow
- Archetype computation backend endpoint
- Old maturity scoring algorithm

### What's MISSING and Must Be BUILT
❌ **Missing - Task 1**:
- 6-dimension maturity assessment frontend integration
- New maturity calculation and display

❌ **Missing - Task 2** (COMPLETELY NEW):
- Role identification decision routing
- Standard roles selection UI (14 clusters)
- Task-based job profile collection
- AI task-to-role mapping
- Target group size collection
- 3 new database tables

❌ **Missing - Task 3** (COMPLETELY NEW):
- 7 SE training strategies data structure
- Strategy selection decision tree engine
- Strategy cards UI with pro-con comparison
- Decision visualization
- Phase 1 review & confirm page
- 2 new database tables

### Estimated Impact
- **Frontend**: ~2,500 lines of new code (6 major components + 12 sub-components)
- **Backend**: ~1,000 lines (new endpoints + decision logic)
- **Database**: 5 new tables + migration script
- **Data**: 2 new data files (14 roles + 7 strategies)
- **Testing**: Full regression + new feature testing required

---

**End of Audit Report**
