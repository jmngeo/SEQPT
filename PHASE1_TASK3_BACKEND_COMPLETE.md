# Phase 1 Task 3: Training Strategy Selection - Backend Implementation COMPLETE

**Date**: 2025-10-19
**Status**: Backend 100% Complete | Frontend Pending
**Session**: Task 3 Implementation - Backend Focus

---

## ✅ COMPLETED WORK (Backend + Data/API Layer)

### 1. Database Layer - COMPLETE ✓

**Model Created:**
- **File**: `src/competency_assessor/app/models.py` (lines 367-418)
- **Class**: `Phase1Strategy`
- **Table**: `phase1_strategies`
- **Status**: ✅ Table created in database

**Fields:**
```python
id, org_id, maturity_id
strategy_id (string) - e.g., 'se_for_managers'
strategy_name (string) - e.g., 'SE for Managers'
priority (string) - 'PRIMARY', 'SECONDARY', 'SUPPLEMENTARY'
reason (text) - Why this strategy was selected
user_selected (boolean) - True if manually selected
auto_recommended (boolean) - True if engine recommended
decision_path (JSONB) - Full decision path
user_preference (string) - For low-maturity secondary choice
warnings (JSONB) - Warnings about strategy fit
created_at, updated_at
```

**Relationships:**
- Links to `Organization` via `org_id`
- Links to `Phase1Maturity` via `maturity_id`

**Migration Script:**
- **File**: `src/competency_assessor/create_phase1_task3_tables.py`
- **Status**: ✅ Successfully executed

---

### 2. Strategy Selection Engine - COMPLETE ✓

**File**: `src/competency_assessor/app/strategy_selection_engine.py` (558 lines)

**Contains:**

#### 2.1 Seven SE Training Strategies (SE_TRAINING_STRATEGIES)

1. **se_for_managers** (FOUNDATIONAL)
   - Target: Management and Leadership
   - Group Size: 5-30 (optimal: 10-20)
   - Duration: 1-2 days workshop
   - Phase: Introductory Phase

2. **common_understanding** (AWARENESS)
   - Target: All stakeholders
   - Group Size: 10-100 (optimal: 20-50)
   - Duration: 2-3 days
   - Phase: Motivation Phase

3. **orientation_pilot** (APPLICATION)
   - Target: Development teams
   - Group Size: 5-20 (optimal: 8-15)
   - Duration: 3-6 months with coaching
   - Phase: Initial Implementation

4. **certification** (SPECIALIZATION)
   - Target: SE specialists and experts
   - Group Size: 1-25 (optimal: 5-15)
   - Duration: 5-10 days intensive
   - Phase: Motivation Phase
   - Options: SE-Zert, CSEP, INCOSE

5. **continuous_support** (SUSTAINMENT)
   - Target: All employees in SE environment
   - Group Size: 20-Unlimited
   - Duration: Ongoing
   - Phase: Continuation Phase

6. **needs_based_project** (TARGETED)
   - Target: Specific roles in projects
   - Group Size: 10-50 (optimal: 15-30)
   - Duration: 6-12 months (project lifecycle)
   - Phase: Implementation Phase

7. **train_the_trainer** (MULTIPLIER)
   - Target: Internal trainers or external providers
   - Group Size: 2-10 (optimal: 4-6)
   - Duration: 10-20 days intensive + practice
   - Phase: All phases (supplementary)

#### 2.2 StrategySelectionEngine Class

**Decision Algorithm:**

```python
Step 1: Evaluate Train-the-Trainer
  IF estimated_count >= 100 OR size_category in ['LARGE', 'VERY_LARGE', 'ENTERPRISE']:
    ADD 'train_the_trainer' as SUPPLEMENTARY
    REASON: "Large target group requires multiplier approach"

Step 2: Main Strategy Selection
  IF se_processes <= 1 (Low Maturity):
    PRIMARY: 'se_for_managers'
    REASON: "Management buy-in essential for SE introduction"
    REQUIRES_USER_CHOICE: True (user selects secondary from 3 options)

  ELSE IF se_processes > 1 (High Maturity):
    IF rollout_scope <= 1 (Narrow Rollout):
      PRIMARY: 'needs_based_project'
      REASON: "SE processes defined but not widely deployed"

    ELSE (Broad Rollout):
      PRIMARY: 'continuous_support'
      REASON: "SE widely deployed - requires continuous support"

Step 3: Validate Against Group Size
  FOR each selected strategy:
    IF target_size > strategy.groupSize.max:
      ADD WARNING: "Strategy typically supports up to X participants. Consider multiple cohorts."
```

**Key Methods:**
- `select_strategies()` - Main entry point, returns dict with strategies, decisionPath, reasoning, requiresUserChoice
- `evaluate_train_the_trainer()` - Checks if large group needs train-the-trainer
- `select_low_maturity_strategies()` - Low maturity path (se_processes ≤ 1)
- `select_high_maturity_strategies(rollout_scope)` - High maturity path
- `validate_against_group_size()` - Adds warnings if capacity exceeded
- `generate_reasoning()` - Creates detailed reasoning object
- Helper methods: `get_maturity_level_name()`, `get_rollout_level_name()`, etc.

**Reasoning Object Structure:**
```python
{
  'maturityFactors': {
    'seProcesses': { value, level, implication },
    'rolloutScope': { value, level, implication },
    'seMindset': { value, level, impact },
    'knowledgeBase': { value, level, impact }
  },
  'targetGroupConsiderations': {
    'size': "100-500",
    'implication': "Needs scalable formats and train-the-trainer approach"
  },
  'recommendations': [
    { type: 'CRITICAL/IMPORTANT/SUGGESTED', message: "..." }
  ]
}
```

---

### 3. Backend API Endpoints - COMPLETE ✓

**File**: `src/competency_assessor/app/routes.py` (lines 2556-2798)

**5 Endpoints Implemented:**

#### 3.1 GET /api/phase1/strategies/definitions
**Purpose**: Fetch all 7 strategy definitions
**Response:**
```json
{
  "success": true,
  "count": 7,
  "strategies": [
    {
      "id": "se_for_managers",
      "name": "SE for Managers",
      "category": "FOUNDATIONAL",
      "description": "...",
      "qualificationLevel": "Understanding",
      "suitablePhase": "Introductory Phase",
      "targetAudience": "Management and Leadership",
      "groupSize": { "min": 5, "max": 30, "optimal": "10-20 managers" },
      "duration": "1-2 days workshop",
      "benefits": ["...", "...", "..."],
      "implementation": { "format": "...", "frequency": "...", "prerequisites": "..." }
    },
    ...
  ]
}
```
**Status**: ✅ Tested successfully

#### 3.2 POST /api/phase1/strategies/calculate
**Purpose**: Calculate recommended strategies based on maturity and target group
**Request Body:**
```json
{
  "maturityData": {
    "rollout_scope": 1,
    "se_processes": 1,
    "se_mindset": 2,
    "knowledge_base": 1,
    "final_score": 45.5,
    "maturity_level": 2
  },
  "targetGroupData": {
    "size_range": "100-500",
    "size_category": "LARGE",
    "estimated_count": 250
  }
}
```

**Response:**
```json
{
  "success": true,
  "strategies": [
    {
      "strategy": "train_the_trainer",
      "strategyName": "Train the SE-Trainer",
      "priority": "SUPPLEMENTARY",
      "reason": "With 100-500 people to train, a train-the-trainer approach will enable scalable knowledge transfer",
      "warning": "Strategy typically supports up to 10 participants. Consider multiple cohorts or alternative approach."
    },
    {
      "strategy": "se_for_managers",
      "strategyName": "SE for Managers",
      "priority": "PRIMARY",
      "reason": "Management buy-in is essential for SE introduction in organizations with undefined processes",
      "warning": "Strategy typically supports up to 30 participants. Consider multiple cohorts or alternative approach."
    }
  ],
  "decisionPath": [
    {
      "step": 1,
      "decision": "Add Train-the-Trainer",
      "reason": "Large target group requires multiplier approach"
    },
    {
      "step": 2,
      "decision": "Select SE for Managers as primary",
      "reason": "SE Processes maturity is \"Ad hoc / Undefined\" - requires management enablement first"
    },
    {
      "step": 3,
      "decision": "User selects secondary strategy",
      "options": ["common_understanding", "orientation_pilot", "certification"]
    }
  ],
  "reasoning": {
    "maturityFactors": { ... },
    "targetGroupConsiderations": { ... },
    "recommendations": [ ... ]
  },
  "requiresUserChoice": true
}
```
**Status**: ✅ Tested successfully (low-maturity, large group scenario)

#### 3.3 POST /api/phase1/strategies/save
**Purpose**: Save selected strategies to database
**Request Body:**
```json
{
  "orgId": 24,
  "maturityId": 5,
  "strategies": [
    {
      "strategy": "se_for_managers",
      "strategyName": "SE for Managers",
      "priority": "PRIMARY",
      "reason": "Management buy-in is essential...",
      "userSelected": false,
      "autoRecommended": true
    }
  ],
  "decisionPath": [ ... ],
  "userPreference": "common_understanding"
}
```

**Response:**
```json
{
  "success": true,
  "count": 2,
  "strategies": [
    {
      "id": 1,
      "orgId": 24,
      "maturityId": 5,
      "strategyId": "se_for_managers",
      "strategyName": "SE for Managers",
      "priority": "PRIMARY",
      "reason": "...",
      "userSelected": false,
      "autoRecommended": true,
      "decisionPath": [ ... ],
      "userPreference": "common_understanding",
      "warnings": null,
      "createdAt": "2025-10-19T21:50:00.000Z"
    }
  ]
}
```
**Status**: Ready (not tested - needs frontend)

#### 3.4 GET /api/phase1/strategies/<org_id>
**Purpose**: Get all strategy selections for an organization
**Status**: Ready

#### 3.5 GET /api/phase1/strategies/<org_id>/latest
**Purpose**: Get latest strategy selection (grouped by maturity_id)
**Status**: Ready

**Imports Added:**
```python
# Line 3 in routes.py
from app.models import Phase1Strategy

# Line 23 in routes.py
from app.strategy_selection_engine import StrategySelectionEngine, SE_TRAINING_STRATEGIES
```

---

### 4. Frontend Data Layer - COMPLETE ✓

**File**: `src/frontend/src/data/seTrainingStrategies.js`

**Exports:**

1. **STRATEGY_CATEGORIES** - Category styling
```javascript
{
  FOUNDATIONAL: { label: 'Foundational', color: '#1976D2' },
  AWARENESS: { label: 'Awareness', color: '#388E3C' },
  APPLICATION: { label: 'Application', color: '#F57C00' },
  SPECIALIZATION: { label: 'Specialization', color: '#7B1FA2' },
  SUSTAINMENT: { label: 'Sustainment', color: '#0097A7' },
  TARGETED: { label: 'Targeted', color: '#C62828' },
  MULTIPLIER: { label: 'Multiplier', color: '#5D4037' }
}
```

2. **PRIORITY_BADGES** - Priority styling
```javascript
{
  PRIMARY: { label: 'Primary', color: 'primary', icon: 'mdi-star' },
  SECONDARY: { label: 'Secondary', color: 'info', icon: 'mdi-star-half-full' },
  SUPPLEMENTARY: { label: 'Supplementary', color: 'success', icon: 'mdi-plus-circle' }
}
```

3. **STRATEGY_PRO_CON** - Pro/Con comparison data for 3 secondary strategies
   - `common_understanding` - 4 pros, 3 cons
   - `orientation_pilot` - 4 pros, 4 cons
   - `certification` - 4 pros, 3 cons

4. **Helper Functions:**
   - `getCategoryInfo(categoryKey)` - Returns category with color
   - `getPriorityInfo(priorityKey)` - Returns priority badge info

---

### 5. Frontend API Layer - COMPLETE ✓

**File**: `src/frontend/src/api/phase1.js` (lines 255-343)

**strategyApi Methods:**

```javascript
export const strategyApi = {
  // Get all 7 strategy definitions
  getDefinitions: async () => {
    const response = await axiosInstance.get('/api/phase1/strategies/definitions')
    return response.data
  },

  // Calculate recommended strategies
  calculate: async (maturityData, targetGroupData) => {
    const response = await axiosInstance.post('/api/phase1/strategies/calculate', {
      maturityData,
      targetGroupData
    })
    return response.data
  },

  // Save selected strategies
  save: async (orgId, maturityId, strategies, decisionPath, userPreference = null) => {
    const response = await axiosInstance.post('/api/phase1/strategies/save', {
      orgId,
      maturityId,
      strategies,
      decisionPath,
      userPreference
    })
    return response.data
  },

  // Get all strategy selections for org
  get: async (orgId) => {
    const response = await axiosInstance.get(`/api/phase1/strategies/${orgId}`)
    return response.data
  },

  // Get latest strategy selection
  getLatest: async (orgId) => {
    const response = await axiosInstance.get(`/api/phase1/strategies/${orgId}/latest`)
    return response.data
  }
}
```

---

### 6. Server Status - RUNNING ✓

- **Flask Backend**: http://127.0.0.1:5003 (Port 5003) - ✅ Running
- **Vite Frontend**: http://localhost:3000 - ✅ Running
- **Database**: `competency_assessment` - ✅ Table created
- **Test Organization**: Org ID 24, Code: JPAWJ_

---

## 🔄 REMAINING WORK (Frontend Vue Components)

### Components to Create:

#### 1. StrategyCard.vue
**Location**: `src/frontend/src/components/phase1/task3/StrategyCard.vue`

**Props:**
- `strategy: Object` - Full strategy from API
- `isSelected: Boolean`
- `isRecommended: Boolean`

**Features:**
- Checkbox for selection
- Recommended badge (if auto-selected)
- Category badge with color
- Name, description
- Details: qualification level, target audience, duration, group size
- Top 3 benefits
- "View Details" button (optional)

**Events:**
- `@toggle` - When checkbox clicked

**Styling**: Vuetify v-card

---

#### 2. ProConComparison.vue
**Location**: `src/frontend/src/components/phase1/task3/ProConComparison.vue`

**Props:**
- `strategies: Array` - ['common_understanding', 'orientation_pilot', 'certification']

**Features:**
- 3-column grid
- Each card: name, description, pros (green), cons (red), "Best For", select button
- Radio button behavior (only one selected)
- Selected card highlights

**Events:**
- `@select(strategyId)` - When user picks secondary

**Data**: Import `STRATEGY_PRO_CON` from data file

---

#### 3. StrategySummary.vue
**Location**: `src/frontend/src/components/phase1/task3/StrategySummary.vue`

**Props:**
- `strategies: Array` - Selected strategies
- `targetGroupSize: Object`

**Features:**
- List of selected strategies with priority badges
- Strategy names and reasons
- Warnings (if any)
- Target group size summary
- Total count

**Styling**: el-card or v-card

---

#### 4. StrategySelection.vue (Main Component)
**Location**: `src/frontend/src/components/phase1/task3/StrategySelection.vue`

**Props:**
- `maturityData: Object` - From Task 1
- `targetGroupData: Object` - From Task 2
- `rolesData: Array` - From Task 2

**Lifecycle:**
```javascript
async mounted() {
  // 1. Fetch definitions
  const defs = await strategyApi.getDefinitions()
  this.allStrategies = defs.strategies

  // 2. Calculate recommendations
  const calc = await strategyApi.calculate(this.maturityData, this.targetGroupData)
  this.recommendedStrategies = calc.strategies
  this.decisionPath = calc.decisionPath
  this.reasoning = calc.reasoning
  this.requiresUserChoice = calc.requiresUserChoice

  // 3. Initialize selection
  this.selectedStrategies = [...this.recommendedStrategies]
}
```

**Methods:**
- `handleSecondaryChoice(strategyId)` - Add user's secondary selection
- `toggleStrategy(strategyId)` - Manual toggle
- `confirmStrategies()` - Save and emit complete

**Events:**
- `@complete` - Emits { strategies, userPreference }

---

#### 5. PhaseOne.vue Integration
**File**: `src/frontend/src/views/phases/PhaseOne.vue`

**Changes:**
```javascript
// 1. Import
import StrategySelection from '@/components/phase1/task3/StrategySelection.vue'

// 2. Add state
const phase1StrategyData = ref(null)

// 3. Update Step 3
<StrategySelection
  v-if="currentStep === 3"
  :maturity-data="phase1MaturityData"
  :target-group-data="phase1TargetGroupData"
  :roles-data="phase1RolesData"
  @complete="handleStrategyComplete"
/>

// 4. Handler
const handleStrategyComplete = async (strategyData) => {
  phase1StrategyData.value = strategyData
  ElMessage.success(`${strategyData.strategies.length} training strategies selected`)
  currentStep.value = 4 // Move to Review
}
```

**Step 4 Enhancement** (Review & Confirm):
Add strategy display to existing review:
```vue
<el-card header="Selected Training Strategies">
  <div v-for="strategy in phase1StrategyData?.strategies">
    <el-tag :type="getPriorityType(strategy.priority)">
      {{ strategy.priority }}
    </el-tag>
    <strong>{{ strategy.strategyName }}</strong>
    <p>{{ strategy.reason }}</p>
  </div>
</el-card>
```

---

## 📊 Data Structures Reference

### Maturity Data (from Task 1):
```javascript
{
  id: 5,
  rollout_scope: 1,      // 0-4
  se_processes: 1,       // 0-5 (KEY: ≤1 = low maturity)
  se_mindset: 2,         // 0-4
  knowledge_base: 1,     // 0-4
  final_score: 45.5,     // 0-100
  maturity_level: 2,     // 1-5
  maturity_name: "Initial"
}
```

### Target Group Data (from Task 2):
```javascript
{
  size_range: "100-500",
  size_category: "LARGE",  // SMALL, MEDIUM, LARGE, VERY_LARGE, ENTERPRISE
  estimated_count: 250,
  recommended_formats: [...],
  train_the_trainer_recommended: true
}
```

### Strategy Object (from API):
```javascript
{
  id: "se_for_managers",
  name: "SE for Managers",
  category: "FOUNDATIONAL",
  description: "...",
  qualificationLevel: "Understanding",
  suitablePhase: "Introductory Phase",
  targetAudience: "Management and Leadership",
  groupSize: { min: 5, max: 30, optimal: "10-20 managers" },
  duration: "1-2 days workshop",
  benefits: ["...", "...", "..."],
  implementation: { format: "...", frequency: "...", prerequisites: "..." }
}
```

### Selected Strategy (for save):
```javascript
{
  strategy: "se_for_managers",
  strategyName: "SE for Managers",
  priority: "PRIMARY",
  reason: "Management buy-in is essential...",
  userSelected: false,
  autoRecommended: true,
  warning: "..." // Optional
}
```

---

## 🧪 Test Scenarios

### Test 1: Low Maturity, Large Group
**Input:**
```javascript
se_processes: 1
estimated_count: 250
```

**Expected Output:**
- PRIMARY: "SE for Managers"
- SUPPLEMENTARY: "Train the SE-Trainer"
- requiresUserChoice: true
- Pro-Con comparison displayed
- User must select from: common_understanding, orientation_pilot, certification

**Status**: ✅ Backend tested with curl

---

### Test 2: High Maturity, Narrow Rollout
**Input:**
```javascript
se_processes: 4
rollout_scope: 1
```

**Expected Output:**
- PRIMARY: "Needs-based Project-oriented Training"
- No secondary choice required
- requiresUserChoice: false

---

### Test 3: High Maturity, Broad Rollout
**Input:**
```javascript
se_processes: 4
rollout_scope: 3
```

**Expected Output:**
- PRIMARY: "Continuous Support"
- No secondary choice required
- requiresUserChoice: false

---

## 🎨 Styling Guidelines

**Framework Mix:**
- **Vuetify** for strategy cards (v-card, v-chip, v-checkbox)
- **Element Plus** for main layout (el-card, el-button, el-message)
- Match existing Task 1 & Task 2 styling

**Colors:**
- PRIMARY badge: `#1976D2` (blue)
- SECONDARY badge: `#0288D1` (info blue)
- SUPPLEMENTARY badge: `#388E3C` (green)
- Recommended badge: `#10b981` (emerald green)

---

## 📝 Files Created/Modified

### Created:
1. `src/competency_assessor/app/strategy_selection_engine.py` (558 lines)
2. `src/competency_assessor/create_phase1_task3_tables.py`
3. `src/frontend/src/data/seTrainingStrategies.js`

### Modified:
1. `src/competency_assessor/app/models.py` - Added Phase1Strategy model (52 lines)
2. `src/competency_assessor/app/routes.py` - Added imports + 5 endpoints (247 lines)
3. `src/frontend/src/api/phase1.js` - Expanded strategyApi (89 lines)

---

## 🔑 Session Handover Checklist

✅ Backend database model created and migrated
✅ Strategy selection engine implemented with all 7 strategies
✅ 5 API endpoints created (2 tested with curl, 3 ready for frontend)
✅ Flask server running with new code loaded (Port 5003)
✅ Frontend data layer created (categories, pro-con data)
✅ Frontend API methods created (5 methods)
⏳ Vue components pending (5 components)
⏳ PhaseOne.vue integration pending
⏳ End-to-end testing pending

---

## 🚀 Next Session: Frontend Component Creation

**Start With:** StrategyCard.vue component

**Test Flow:**
1. Navigate to: http://localhost:3000/app/phases/1
2. Complete Task 1 (Maturity Assessment)
3. Complete Task 2 (Role Identification + Target Group)
4. Proceed to Task 3 (Strategy Selection) - NEW
5. Review & Confirm all Phase 1 data

**Test User:**
- Org ID: 24
- Org Code: JPAWJ_
- User ID: 30
- Role: admin

---

**Backend Implementation: 100% COMPLETE ✓**
**Frontend Implementation: 0% COMPLETE (Ready to Start)**
**Overall Task 3 Progress: ~50%**
