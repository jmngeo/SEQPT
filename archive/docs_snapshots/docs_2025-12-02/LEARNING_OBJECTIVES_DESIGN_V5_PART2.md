# Learning Objectives Generation - Design v5 Part 2

**Continuation of:** LEARNING_OBJECTIVES_DESIGN_V5_FINAL.md

---

## UI Components

### Component Hierarchy

```
LearningObjectivesPage
├── ValidationSummary (optional, informational)
├── ViewSelector (Toggle: Organizational vs Role-Based)
├── IF Organizational View:
│   └── OrganizationalPyramid
│       ├── PyramidLevelTabs (1, 2, 4, 6)
│       └── CompetencyList (per level)
│           └── CompetencyCard (×16 per level)
│               ├── CompetencyHeader
│               ├── LearningObjectiveText (if training required)
│               ├── RoleList (if high maturity)
│               │   └── RoleCard (×N roles)
│               │       ├── RoleInfo (name, users needing)
│               │       └── TrainingRecommendation
│               └── OrganizationalStats (if low maturity)
│
└── IF Role-Based View:
    └── RoleBasedPyramid
        ├── RoleSelector (dropdown)
        ├── PyramidLevelTabs (1, 2, 4, 6)
        └── CompetencyList (filtered for selected role)
            └── CompetencyCard (×N competencies with gaps)
                ├── CompetencyHeader
                ├── LearningObjectiveText
                └── RoleSpecificStats
```

### Component Specifications

#### 1. LearningObjectivesPage.vue

**Purpose:** Main container component

**Props:** None (loads org_id from store)

**State:**
```javascript
{
  pyramidData: Object,      // From API
  currentView: 'organizational' | 'role-based',
  selectedRole: Number | null,
  loading: Boolean,
  error: String | null
}
```

**Methods:**
- `loadLearningObjectives()` - API call
- `switchView(viewType)` - Toggle between views
- `selectRole(roleId)` - For role-based view

**Template Structure:**
```vue
<template>
  <div class="learning-objectives-page">
    <!-- Header -->
    <h1>Learning Objectives - Phase 2 Task 3</h1>

    <!-- Validation Summary (if applicable) -->
    <ValidationSummary
      v-if="pyramidData.metadata.validation"
      :validation="pyramidData.metadata.validation"
    />

    <!-- View Selector -->
    <ViewSelector
      :current-view="currentView"
      :has-roles="pyramidData.metadata.has_roles"
      @switch-view="switchView"
    />

    <!-- Main Content -->
    <div v-if="loading">Loading...</div>
    <div v-else-if="error">Error: {{ error }}</div>
    <div v-else>
      <!-- Organizational View -->
      <OrganizationalPyramid
        v-if="currentView === 'organizational'"
        :pyramid-data="pyramidData"
      />

      <!-- Role-Based View -->
      <RoleBasedPyramid
        v-else-if="currentView === 'role-based'"
        :pyramid-data="pyramidData"
        :selected-role="selectedRole"
        @role-selected="selectRole"
      />
    </div>
  </div>
</template>
```

---

#### 2. ViewSelector.vue

**Purpose:** Toggle between Organizational and Role-Based views

**Props:**
```javascript
{
  currentView: String,  // 'organizational' or 'role-based'
  hasRoles: Boolean     // From metadata
}
```

**Template:**
```vue
<template>
  <div class="view-selector">
    <v-btn-toggle v-model="selectedView" mandatory>
      <v-btn value="organizational">
        <v-icon left>mdi-domain</v-icon>
        Organizational View
      </v-btn>

      <v-btn
        value="role-based"
        :disabled="!hasRoles"
        :title="hasRoles ? 'View by specific role' : 'No roles defined (low maturity)'"
      >
        <v-icon left>mdi-account-group</v-icon>
        Role-Based View
      </v-btn>
    </v-btn-toggle>

    <v-alert v-if="!hasRoles && selectedView === 'role-based'" type="info">
      Role-based view not available - your organization has not defined roles (low maturity).
    </v-alert>
  </div>
</template>
```

---

#### 3. OrganizationalPyramid.vue

**Purpose:** Display pyramid structure with all roles aggregated

**Props:**
```javascript
{
  pyramidData: Object  // Full pyramid structure from API
}
```

**State:**
```javascript
{
  currentLevel: Number  // 1, 2, 4, or 6
}
```

**Template:**
```vue
<template>
  <div class="organizational-pyramid">
    <!-- Pyramid Level Tabs -->
    <v-tabs v-model="currentLevel">
      <v-tab
        v-for="levelNum in [1, 2, 4, 6]"
        :key="levelNum"
        :value="levelNum"
        :class="{ 'grayed-out': pyramidData.levels[levelNum].grayed_out }"
      >
        <v-icon v-if="pyramidData.levels[levelNum].grayed_out" left>
          mdi-check-circle
        </v-icon>
        Level {{ levelNum }}: {{ pyramidData.levels[levelNum].level_name }}
      </v-tab>
    </v-tabs>

    <!-- Level Content -->
    <v-window v-model="currentLevel">
      <v-window-item
        v-for="levelNum in [1, 2, 4, 6]"
        :key="levelNum"
        :value="levelNum"
      >
        <LevelView
          :level-data="pyramidData.levels[levelNum]"
          :has-roles="pyramidData.metadata.has_roles"
        />
      </v-window-item>
    </v-window>
  </div>
</template>
```

---

#### 4. LevelView.vue

**Purpose:** Display all 16 competencies for one pyramid level

**Props:**
```javascript
{
  levelData: Object,  // Data for this specific level
  hasRoles: Boolean   // Whether to show role information
}
```

**Computed:**
```javascript
{
  activeCompetencies: Array,  // Competencies needing training
  grayedCompetencies: Array   // Competencies already achieved
}
```

**Template:**
```vue
<template>
  <div class="level-view">
    <!-- Gray Out Message (if entire level grayed) -->
    <v-alert v-if="levelData.grayed_out" type="info">
      <v-icon left>mdi-check-circle</v-icon>
      {{ levelData.gray_reason }}
    </v-alert>

    <!-- Competency Cards -->
    <div class="competency-grid">
      <!-- Active Competencies First -->
      <CompetencyCard
        v-for="comp in activeCompetencies"
        :key="comp.competency_id"
        :competency="comp"
        :has-roles="hasRoles"
        :grayed-out="false"
      />

      <!-- Grayed Competencies -->
      <CompetencyCard
        v-for="comp in grayedCompetencies"
        :key="comp.competency_id"
        :competency="comp"
        :has-roles="hasRoles"
        :grayed-out="true"
      />
    </div>
  </div>
</template>

<style scoped>
.competency-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 20px;
  margin-top: 20px;
}
</style>
```

---

#### 5. CompetencyCard.vue

**Purpose:** Display one competency with LO and role/stats

**Props:**
```javascript
{
  competency: Object,   // Competency data
  hasRoles: Boolean,    // Show roles or organizational stats
  grayedOut: Boolean    // Visual styling
}
```

**Template:**
```vue
<template>
  <v-card
    :class="{ 'grayed-out-card': grayedOut }"
    elevation="2"
  >
    <!-- Header -->
    <v-card-title>
      <v-icon v-if="grayedOut" left color="success">mdi-check</v-icon>
      <v-icon v-else left color="primary">mdi-school</v-icon>
      {{ competency.competency_name }}
    </v-card-title>

    <v-card-subtitle>
      <span v-if="competency.status === 'training_required'">
        Target Level: {{ competency.target_level }}
      </span>
      <span v-else class="achieved-text">
        {{ competency.message }}
      </span>
    </v-card-subtitle>

    <!-- Content (if training required) -->
    <v-card-text v-if="competency.status === 'training_required' && !grayedOut">
      <!-- Learning Objective -->
      <div class="learning-objective">
        <h4>Learning Objective (Level {{ competency.learning_objective.level }}):</h4>
        <p>{{ competency.learning_objective.objective_text }}</p>
        <v-chip v-if="competency.learning_objective.customized" small color="secondary">
          <v-icon left small>mdi-cog</v-icon>
          PMT Customized
        </v-chip>
      </div>

      <!-- Role Information (High Maturity) -->
      <div v-if="hasRoles && competency.roles" class="roles-section">
        <h4>Roles needing this competency:</h4>
        <RoleCard
          v-for="role in competency.roles"
          :key="role.role_id"
          :role="role"
        />
      </div>

      <!-- Organizational Stats (Low Maturity) -->
      <div v-else-if="!hasRoles && competency.organizational_stats" class="org-stats">
        <h4>Organizational Statistics:</h4>
        <v-list dense>
          <v-list-item>
            <v-list-item-content>
              <v-list-item-title>Users needing training:</v-list-item-title>
              <v-list-item-subtitle>
                {{ competency.organizational_stats.users_needing_training }} /
                {{ competency.organizational_stats.total_users }}
                ({{ (competency.organizational_stats.gap_percentage * 100).toFixed(0) }}%)
              </v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>

          <v-list-item>
            <v-list-item-content>
              <v-list-item-title>Median Level:</v-list-item-title>
              <v-list-item-subtitle>
                {{ competency.organizational_stats.median_level }}
              </v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>

          <v-list-item>
            <v-list-item-content>
              <v-list-item-title>Training Recommendation:</v-list-item-title>
              <v-list-item-subtitle>
                <v-chip small :color="getRecommendationColor(competency.organizational_stats.training_recommendation)">
                  <v-icon left small>
                    {{ competency.organizational_stats.training_recommendation.icon }}
                  </v-icon>
                  {{ competency.organizational_stats.training_recommendation.method }}
                </v-chip>
              </v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>
        </v-list>

        <v-alert dense type="info">
          {{ competency.organizational_stats.training_recommendation.rationale }}
        </v-alert>
      </div>
    </v-card-text>

    <!-- Grayed Out Content -->
    <v-card-text v-else-if="grayedOut">
      <p class="achieved-message">
        <v-icon left color="success">mdi-check-circle</v-icon>
        {{ competency.message || 'Already at target level or higher' }}
      </p>
    </v-card-text>
  </v-card>
</template>

<style scoped>
.grayed-out-card {
  opacity: 0.6;
  background-color: #f5f5f5;
}

.learning-objective {
  margin-bottom: 20px;
  padding: 15px;
  background-color: #e3f2fd;
  border-left: 4px solid #2196f3;
}

.roles-section, .org-stats {
  margin-top: 20px;
}

.achieved-text, .achieved-message {
  color: #4caf50;
  font-weight: 500;
}
</style>
```

---

#### 6. RoleCard.vue

**Purpose:** Display role-specific information within competency card

**Props:**
```javascript
{
  role: Object  // Role data with stats
}
```

**Template:**
```vue
<template>
  <v-card outlined class="role-card">
    <v-card-subtitle>
      <v-icon left>mdi-account-group</v-icon>
      {{ role.role_name }}
    </v-card-subtitle>

    <v-card-text>
      <v-row dense>
        <v-col cols="6">
          <div class="stat-item">
            <span class="stat-label">Users needing training:</span>
            <span class="stat-value">
              {{ role.users_needing }} / {{ role.total_users }}
              ({{ (role.percentage * 100).toFixed(0) }}%)
            </span>
          </div>
        </v-col>

        <v-col cols="6">
          <div class="stat-item">
            <span class="stat-label">Median Level:</span>
            <span class="stat-value">{{ role.median_level }}</span>
          </div>
        </v-col>
      </v-row>

      <!-- Training Recommendation -->
      <v-divider class="my-2"></v-divider>
      <div class="training-recommendation">
        <v-chip small :color="getRecommendationColor(role.training_recommendation)">
          <v-icon left small>{{ role.training_recommendation.icon }}</v-icon>
          {{ role.training_recommendation.method }}
        </v-chip>
        <p class="recommendation-rationale">
          {{ role.training_recommendation.rationale }}
        </p>
      </div>
    </v-card-text>
  </v-card>
</template>

<style scoped>
.role-card {
  margin-bottom: 12px;
}

.stat-item {
  display: flex;
  flex-direction: column;
}

.stat-label {
  font-size: 0.85em;
  color: #666;
}

.stat-value {
  font-weight: 600;
  font-size: 1.1em;
}

.recommendation-rationale {
  margin-top: 8px;
  font-size: 0.9em;
  color: #555;
}
</style>
```

---

#### 7. RoleBasedPyramid.vue

**Purpose:** Display pyramid filtered for one specific role

**Props:**
```javascript
{
  pyramidData: Object,
  selectedRole: Number | null
}
```

**State:**
```javascript
{
  currentLevel: Number,
  availableRoles: Array
}
```

**Computed:**
```javascript
{
  filteredPyramidData: Object  // Pyramid data filtered for selected role
}
```

**Methods:**
- `filterDataForRole(roleId)` - Filter pyramid data

**Template:**
```vue
<template>
  <div class="role-based-pyramid">
    <!-- Role Selector -->
    <v-select
      v-model="localSelectedRole"
      :items="availableRoles"
      item-title="name"
      item-value="id"
      label="Select Role"
      prepend-icon="mdi-account-group"
      @update:model-value="onRoleChange"
    />

    <!-- Pyramid Levels (if role selected) -->
    <div v-if="localSelectedRole">
      <v-tabs v-model="currentLevel">
        <v-tab
          v-for="levelNum in [1, 2, 4, 6]"
          :key="levelNum"
          :value="levelNum"
          :class="{ 'grayed-out': isLevelGrayedForRole(levelNum) }"
        >
          Level {{ levelNum }}: {{ getLevelName(levelNum) }}
        </v-tab>
      </v-tabs>

      <v-window v-model="currentLevel">
        <v-window-item
          v-for="levelNum in [1, 2, 4, 6]"
          :key="levelNum"
          :value="levelNum"
        >
          <RoleLevelView
            :level-num="levelNum"
            :role-id="localSelectedRole"
            :pyramid-data="pyramidData"
          />
        </v-window-item>
      </v-window>
    </div>

    <!-- Placeholder (no role selected) -->
    <v-alert v-else type="info">
      Please select a role to view its specific training needs.
    </v-alert>
  </div>
</template>
```

---

#### 8. ValidationSummary.vue

**Purpose:** Display strategy validation information (informational only)

**Props:**
```javascript
{
  validation: Object  // Validation result from API
}
```

**Template:**
```vue
<template>
  <v-alert
    type="info"
    prominent
    border="left"
    colored-border
    elevation="2"
    class="validation-summary"
  >
    <v-row align="center">
      <v-col cols="12" md="8">
        <div class="validation-message">
          <v-icon left>mdi-information</v-icon>
          {{ validation.message }}
        </div>
      </v-col>

      <v-col cols="12" md="4" class="text-right">
        <v-chip small color="success">
          <v-icon left small>mdi-check</v-icon>
          {{ validation.aligned_count }} aligned
        </v-chip>
        <v-chip small color="info">
          <v-icon left small>mdi-arrow-down</v-icon>
          {{ validation.below_count }} below
        </v-chip>
        <v-chip small color="warning">
          <v-icon left small>mdi-arrow-up</v-icon>
          {{ validation.above_count }} above
        </v-chip>
      </v-col>
    </v-row>

    <!-- Details (expandable) -->
    <v-expansion-panels v-if="validation.details" class="mt-3">
      <v-expansion-panel>
        <v-expansion-panel-title>View Details</v-expansion-panel-title>
        <v-expansion-panel-text>
          <div v-if="validation.details.below_target.length > 0">
            <h4>Below Target (Training Needed):</h4>
            <v-list dense>
              <v-list-item
                v-for="comp in validation.details.below_target"
                :key="comp.name"
              >
                <v-list-item-content>
                  <v-list-item-title>{{ comp.name }}</v-list-item-title>
                  <v-list-item-subtitle>
                    Current: {{ comp.current }}, Target: {{ comp.target }}, Gap: {{ comp.gap }}
                  </v-list-item-subtitle>
                </v-list-item-content>
              </v-list-item>
            </v-list>
          </div>

          <div v-if="validation.details.above_target.length > 0" class="mt-3">
            <h4>Already Exceed Target:</h4>
            <v-list dense>
              <v-list-item
                v-for="comp in validation.details.above_target"
                :key="comp.name"
              >
                <v-list-item-content>
                  <v-list-item-title>{{ comp.name }}</v-list-item-title>
                  <v-list-item-subtitle>
                    Current: {{ comp.current }}, Target: {{ comp.target }}, Surplus: {{ comp.surplus }}
                  </v-list-item-subtitle>
                </v-list-item-content>
              </v-list-item>
            </v-list>
          </div>
        </v-expansion-panel-text>
      </v-expansion-panel>
    </v-expansion-panels>
  </v-alert>
</template>

<style scoped>
.validation-summary {
  margin-bottom: 24px;
}

.validation-message {
  font-size: 1.1em;
  font-weight: 500;
}
</style>
```

---

## API Endpoints

### Endpoint 1: Generate Learning Objectives

**Method:** POST
**URL:** `/api/phase2/task3/generate-learning-objectives`

**Request Body:**
```json
{
  "organization_id": 28,
  "selected_strategies": [
    {
      "strategy_id": 1,
      "strategy_name": "Continuous Support"
    }
  ],
  "pmt_context": {
    "processes": "ISO 26262, V-model, Agile Development",
    "methods": "Scrum, Requirements Traceability, Trade Studies",
    "tools": "DOORS, JIRA, Enterprise Architect"
  }
}
```

**Response:** See "Output Structure" in Part 1

**Error Responses:**
- 400: Invalid request data
- 404: Organization not found
- 500: Server error

---

### Endpoint 2: Get Organization Roles

**Method:** GET
**URL:** `/api/organizations/{org_id}/roles`

**Response:**
```json
{
  "success": true,
  "data": {
    "has_roles": true,
    "roles": [
      {
        "role_id": 1,
        "role_name": "Requirements Engineer",
        "user_count": 10
      },
      {
        "role_id": 2,
        "role_name": "System Architect",
        "user_count": 8
      }
    ]
  }
}
```

---

### Endpoint 3: Get Competency Templates

**Method:** GET
**URL:** `/api/learning-objectives/templates`

**Query Parameters:**
- `competency_id` (optional): Filter by competency
- `level` (optional): Filter by level

**Response:**
```json
{
  "success": true,
  "data": {
    "templates": [
      {
        "competency_id": 1,
        "competency_name": "Systems Thinking",
        "level": 2,
        "level_name": "Understanding SE",
        "objective_text": "Participants understand the principles...",
        "requires_pmt": false
      }
    ]
  }
}
```

---

## Implementation Plan

### Phase 2A: Backend Core (Week 1-2)

**Tasks:**
1. Implement gap detection algorithms ✓ Priority
   - `detect_gaps()` function
   - `process_competency_with_roles()`
   - `process_competency_without_roles()`

2. Implement distribution statistics calculation
   - Median, mean, variance
   - Gap percentage
   - Training method determination

3. Implement LO generation logic
   - Template loading
   - PMT customization
   - Progressive level generation

4. Implement pyramid structuring
   - Level organization
   - Graying out logic
   - Validation integration

5. Create API endpoint
   - Request validation
   - Error handling
   - Response formatting

**Test Coverage:**
- Unit tests for each algorithm
- Integration tests for full flow
- Test with org 28 (high maturity) and org 29 (low maturity)

---

### Phase 2B: Frontend Core (Week 3-4)

**Tasks:**
1. Create component structure
   - LearningObjectivesPage
   - OrganizationalPyramid
   - RoleBasedPyramid

2. Implement pyramid level navigation
   - Tab switching
   - Level content display
   - Graying out styling

3. Implement competency cards
   - Active vs grayed styling
   - LO display
   - Role/stats display

4. Implement view toggling
   - Organizational vs Role-Based
   - Role selector
   - Data filtering

5. Implement validation summary
   - Info display
   - Details expansion

**Test Coverage:**
- Component unit tests
- Integration tests
- E2E tests for navigation

---

### Phase 2C: Polish & Testing (Week 5)

**Tasks:**
1. UI/UX refinements
   - Styling consistency
   - Responsive design
   - Loading states
   - Error handling

2. Comprehensive testing
   - Test all distribution scenarios
   - Test both high and low maturity
   - Test role-based view
   - Test validation

3. Documentation
   - Code comments
   - API documentation
   - User guide

4. Bug fixes and optimization

---

### Phase 2D: Integration (Week 6)

**Tasks:**
1. Integrate with Phase 1 output
   - Strategy selection data
   - PMT context data

2. Integrate with Phase 2 Task 1-2 output
   - Assessment data
   - Role assignments

3. End-to-end testing
   - Full workflow (Phase 1 → Phase 2 Task 3)
   - Multiple test organizations

4. Prepare for Phase 3 handoff
   - Data structures ready
   - Training recommendations stored

---

## Testing Strategy

### Unit Tests

**Backend:**
- Test each algorithm independently
- Mock data for consistent results
- Edge cases: Empty data, single user, all experts, all beginners

**Frontend:**
- Test each component in isolation
- Mock API responses
- Test computed properties
- Test event emissions

---

### Integration Tests

**Backend:**
- Test full API endpoint
- Test with real database
- Test multiple organizations
- Test PMT customization

**Frontend:**
- Test component interactions
- Test navigation flows
- Test API integration
- Test state management

---

### E2E Tests

**Scenarios:**
1. High maturity org with roles → Organizational view
2. High maturity org with roles → Role-based view
3. Low maturity org without roles → Organizational view only
4. Organization with bimodal distribution
5. Organization with all competencies achieved
6. Organization with PMT customization

---

### Test Data Requirements

**Organizations:**
- Org 28: High maturity, has roles, diverse distributions
- Org 29: High maturity, has roles, tight clustering
- Org 30: Low maturity, no roles, standard template
- Org 31: Edge cases (all beginners, all experts, bimodal)

**Competency Distributions:**
- Test all 10 scenarios from Distribution Analysis document
- Ensure training recommendations are accurate

---

## Migration from v4

### What to Keep:
- PMT customization logic ✓
- Template loading ✓
- Strategy target lookup ✓
- Dual-track processing (Train the Trainer) ✓

### What to Change:
- ❌ Remove strategy-based organization for low maturity
- ❌ Remove per-competency best-fit strategy selection
- ✓ Add "any gap" detection logic (replace median-based decision)
- ✓ Add progressive level generation
- ✓ Add pyramid structure organization
- ✓ Add distribution statistics calculation
- ✓ Add role-based view

### What to Add:
- ✓ Two-view system (organizational + role-based)
- ✓ Training method recommendation logic
- ✓ Validation summary (informational)
- ✓ Graying out logic for levels
- ✓ Show all 16 competencies per level

---

## Success Criteria

**Functional:**
- ✓ Generates LO if ANY user has gap
- ✓ Progressive objectives across all needed levels
- ✓ Both views work (organizational + role-based)
- ✓ Pyramid structure for both pathways
- ✓ Distribution statistics calculated and displayed
- ✓ Training recommendations shown
- ✓ Validation summary displayed
- ✓ PMT customization works

**Performance:**
- API response < 2 seconds for typical org (50 users)
- Frontend renders smoothly (no lag)
- Navigation between levels is instant

**UX:**
- Clear visual distinction between active and grayed competencies
- Easy navigation between pyramid levels
- Role-based view is intuitive
- Training recommendations are clear and actionable
- Validation info is informative but not intrusive

---

## Open Questions / Decisions Needed

**None - all clarified by Jomon on 2025-11-24**

---

## References

- **CLARIFICATIONS_FROM_JOMON_2025-11-24.md** - All design decisions clarified
- **DISTRIBUTION_SCENARIO_ANALYSIS.md** - Distribution patterns and training recommendations
- **TRAINING_METHODS.md** - Catalog of SE training approaches
- **BACKLOG.md** - Features deferred to Phase 3
- **LEARNING_OBJECTIVES_COMPLETE_DESIGN_v4.md** - Previous design (for migration reference)

---

**Document Status:** FINAL - Ready for Implementation
**Date:** 2025-11-24
**Next Step:** Begin Phase 2A Backend Core implementation
