# Derik's Phase 2 Competency Assessment - Complete Analysis

**Date:** 2025-10-20
**Purpose:** Comprehensive analysis of Derik's original competency assessment implementation to guide Phase 2 refactoring

---

## 16 SE Competencies in Database

### Complete List (Retrieved from Database)

| ID | Competency Name | Area |
|----|----------------|------|
| 1 | **Systems Thinking** | Core |
| 4 | **Lifecycle Consideration** | Core |
| 5 | **Customer / Value Orientation** | Core |
| 6 | **Systems Modelling and Analysis** | Core |
| 7 | **Communication** | Social / Personal |
| 8 | **Leadership** | Social / Personal |
| 9 | **Self-Organization** | Social / Personal |
| 10 | **Project Management** | Management |
| 11 | **Decision Management** | Management |
| 12 | **Information Management** | Management |
| 13 | **Configuration Management** | Management |
| 14 | **Requirements Definition** | Technical |
| 15 | **System Architecting** | Technical |
| 16 | **Integration, Verification, Validation** | Technical |
| 17 | **Operation and Support** | Technical |
| 18 | **Agile Methods** | Technical |

**Total:** 16 competencies across 4 areas (Core, Social/Personal, Management, Technical)

**Note:** IDs are not sequential (1, 4-18) - likely from original data import

---

## Derik's Competency Assessment Workflow

### Overview

Derik's implementation uses a **4-level competency indicator system** with a card-based selection interface. Users progress through all 16 competencies sequentially, selecting which level(s) they identify with for each competency.

---

## Frontend Implementation

### Component: CompetencySurvey.vue

**Location:** `sesurveyapp-main/frontend/src/components/CompetencySurvey.vue`

#### Key Features:

1. **Sequential Competency Assessment**
   - One competency at a time
   - Progress indicator: "Question X of Y"
   - Navigation: Back/Next buttons

2. **5-Group Selection System**
   ```
   Group 1: "Kennen" (Know) - Level 1
   Group 2: "Verstehen" (Understand) - Level 2
   Group 3: "Anwenden" (Apply) - Level 4
   Group 4: "Beherrschen" (Master) - Level 6
   Group 5: "None of these" - Level 0
   ```

3. **Multi-Select with Exclusion**
   - Users can select multiple groups (1-4)
   - Selecting "None of these" (Group 5) deselects all others
   - Selecting any group (1-4) deselects Group 5

4. **Card-Based UI**
   ```vue
   <v-card
     class="indicator-card"
     :class="{ 'selected': selectedGroups.includes(index + 1) }"
     @click="selectGroup(index + 1)"
   >
     <v-card-text>
       <strong>Group {{ index + 1 }}</strong>
       <!-- Display competency indicators for this level -->
       <p v-for="indicator in levelGroup.indicators">
         {{ indicator.indicator_en }}
       </p>
     </v-card-text>
   </v-card>
   ```

5. **Responsive Layout**
   - Grid layout with 5 columns (Groups 1-5)
   - Each card shows 3 competency indicators for that level
   - Cards are clickable and highlight when selected

#### Data Flow:

```javascript
// 1. On component mount - Fetch required competencies
onMounted(async () => {
  const response = await axios.post(
    `${API_BASE_URL}/get_required_competencies_for_roles`,
    {
      role_ids: userStore.selectedRoles.map(role => role.id),
      organization_id: userStore.organizationId,
      user_name: userStore.username,
      survey_type: userStore.surveyType
    }
  );
  competencies.value = response.data.competencies;
  await fetchIndicators(); // Fetch indicators for first competency
});

// 2. Fetch indicators for current competency
const fetchIndicators = async () => {
  const competencyId = competencies.value[currentCompetencyIndex.value].competency_id;
  const response = await axios.get(
    `${API_BASE_URL}/get_competency_indicators_for_competency/${competencyId}`
  );
  currentIndicatorsByLevel.value = response.data; // Grouped by level
};

// 3. User selects groups and proceeds
const proceedToNext = () => {
  userStore.addOrUpdateCompetencySelections({
    competencyId: competencies.value[currentCompetencyIndex.value].competency_id,
    selectedGroups: [...selectedGroups.value]
  });

  if (currentCompetencyIndex.value < competencies.value.length - 1) {
    currentCompetencyIndex.value++;
    fetchIndicators(); // Load next competency
  } else {
    isSubmitModalVisible.value = true; // Show submit modal
  }
};

// 4. Submit survey
const submitSurvey = async () => {
  const competencyScores = userStore.competencySelections.map(selection => {
    const maxGroup = Math.max(...selection.selectedGroups);
    let score = 0;

    if (maxGroup === 1) score = 1;       // kennen
    else if (maxGroup === 2) score = 2;  // verstehen
    else if (maxGroup === 3) score = 4;  // anwenden
    else if (maxGroup === 4) score = 6;  // beherrschen
    else score = 0;                      // None of these

    return {
      competencyId: selection.competencyId,
      score: score
    };
  });

  await axios.post(`${API_BASE_URL}/submit_survey`, {
    organization_id: userStore.organizationId,
    username: userStore.username,
    competency_scores: competencyScores,
    survey_type: userStore.surveyType
  });

  router.push('/surveyCompletion');
};
```

#### Score Mapping:

```
Selected Group → Competency Score
Group 1 → 1 (kennen / know)
Group 2 → 2 (verstehen / understand)
Group 3 → 4 (anwenden / apply)
Group 4 → 6 (beherrschen / master)
Group 5 → 0 (none / not applicable)

If multiple groups selected: MAX(selectedGroups) is used
```

---

### Component: SurveyResults.vue

**Location:** `sesurveyapp-main/frontend/src/components/SurveyResults.vue`

#### Key Features:

1. **Radar Chart Visualization**
   - Uses Chart.js with Vue-ChartJS
   - 2 datasets: User Score vs. Required Score
   - Filterable by competency area (Core, Technical, Management, Social/Personal)

2. **Competency Area Selection**
   ```vue
   <v-chip
     :color="selectedAreas.includes(area) ? '#ECB365' : 'grey'"
     @click="toggleAreaSelection(area)"
   >
     {{ area }}
   </v-chip>
   ```

3. **LLM-Generated Feedback Display**
   - Grouped by competency area
   - For each competency:
     - Competency name
     - User strengths
     - Improvement areas

4. **PDF Export**
   - Uses jsPDF + html2canvas
   - Includes:
     - User info
     - Selected roles (for known_roles survey)
     - Recommended roles (for all_roles survey)
     - Radar chart snapshot
     - Full feedback text

5. **Survey Type Handling**
   - `known_roles`: Display selected roles
   - `unknown_roles`: Display task-based assessment
   - `all_roles`: Display most similar matching roles

#### Data Flow:

```javascript
// 1. On mount - Fetch results
onMounted(async () => {
  const response = await axios.get(
    `${API_BASE_URL}/get_user_competency_results`,
    {
      params: {
        username: userStore.username,
        organization_id: userStore.organizationId,
        survey_type: userStore.surveyType
      }
    }
  );

  userScores.value = response.data.user_scores;        // User's scores
  maxScores.value = response.data.max_scores;          // Required scores
  feedbackData.value = response.data.feedback_list;    // LLM feedback
  mostSimilarRole.value = response.data.most_similar_role; // For all_roles

  updateChartData();
});

// 2. Update chart based on selected areas
const updateChartData = () => {
  const competencyLabels = filteredUserScores.value.map(score => score.competency_name);
  const userData = filteredUserScores.value.map(score => score.score);
  const maxData = filteredMaxScores.value.map(score => score.max_score);

  chartData.value = {
    labels: competencyLabels,
    datasets: [
      {
        label: 'User Score',
        data: userData,
        backgroundColor: 'rgba(76, 175, 80, 0.2)',
        borderColor: 'rgba(76, 175, 80, 1)'
      },
      {
        label: 'Required Score',
        data: maxData,
        backgroundColor: 'rgba(255, 99, 132, 0.2)',
        borderColor: 'rgba(255, 99, 132, 1)'
      }
    ]
  };
};
```

---

## Backend Implementation

### API Endpoints

#### 1. Get Required Competencies

**Endpoint:** `POST /get_required_competencies_for_roles`

**Purpose:** Fetch distinct competencies with maximum competency values for selected roles

**Request:**
```json
{
  "role_ids": [1, 3, 5],
  "organization_id": 123,
  "user_name": "se_survey_user_456",
  "survey_type": "known_roles"
}
```

**Backend Logic:**
```python
@main.route('/get_required_competencies_for_roles', methods=['POST'])
def get_required_competencies_for_roles():
    data = request.json
    role_ids = data.get('role_ids')
    organization_id = data.get('organization_id')
    survey_type = data.get('survey_type')

    if survey_type == 'known_roles':
        # Query role_competency_matrix for selected roles
        competencies = (
            db.session.query(
                RoleCompetencyMatrix.competency_id,
                func.max(RoleCompetencyMatrix.role_competency_value).label('max_value')
            )
            .filter(
                RoleCompetencyMatrix.role_cluster_id.in_(role_ids),
                RoleCompetencyMatrix.organization_id == organization_id
            )
            .group_by(RoleCompetencyMatrix.competency_id)
            .order_by(RoleCompetencyMatrix.competency_id)
            .all()
        )

        # Format result
        result = [
            {
                "competency_id": comp.competency_id,
                "required_level": comp.max_value
            }
            for comp in competencies
        ]

        return jsonify({"competencies": result})

    elif survey_type == 'unknown_roles':
        # Use unknown_role_competency_matrix
        competencies = UnknownRoleCompetencyMatrix.query.filter_by(
            organization_id=organization_id,
            user_name=user_name
        ).all()

        result = [
            {
                "competency_id": comp.competency_id,
                "required_level": comp.role_competency_value
            }
            for comp in competencies
        ]

        return jsonify({"competencies": result})

    elif survey_type == 'all_roles':
        # Return all 16 competencies
        all_competencies = Competency.query.all()
        result = [
            {
                "competency_id": comp.id,
                "required_level": 6  # Max level for all competencies
            }
            for comp in all_competencies
        ]

        return jsonify({"competencies": result})
```

**Response:**
```json
{
  "competencies": [
    {
      "competency_id": 1,
      "required_level": 4
    },
    {
      "competency_id": 5,
      "required_level": 2
    },
    // ... all required competencies
  ]
}
```

#### 2. Get Competency Indicators

**Endpoint:** `GET /get_competency_indicators_for_competency/<competency_id>`

**Purpose:** Fetch indicators for a specific competency, grouped by level

**Backend Logic:**
```python
@main.route('/get_competency_indicators_for_competency/<int:competency_id>', methods=['GET'])
def get_competency_indicators_for_competency(competency_id):
    # Fetch all indicators for this competency
    indicators = CompetencyIndicator.query.filter_by(
        competency_id=competency_id
    ).all()

    # Group by level
    grouped_indicators = defaultdict(list)
    for indicator in indicators:
        grouped_indicators[indicator.level].append({
            'indicator_en': indicator.indicator_en,
            'indicator_de': indicator.indicator_de
        })

    # Convert to list format
    result = []
    for level in ['kennen', 'verstehen', 'anwenden', 'beherrschen']:
        if level in grouped_indicators:
            result.append({
                'level': level,
                'indicators': grouped_indicators[level]
            })

    return jsonify(result)
```

**Response:**
```json
[
  {
    "level": "kennen",
    "indicators": [
      {
        "indicator_en": "I know what systems thinking means",
        "indicator_de": "Ich weiß, was Systemdenken bedeutet"
      },
      {
        "indicator_en": "I can define systems thinking",
        "indicator_de": "Ich kann Systemdenken definieren"
      }
      // ... 3 indicators per level
    ]
  },
  {
    "level": "verstehen",
    "indicators": [...]
  },
  {
    "level": "anwenden",
    "indicators": [...]
  },
  {
    "level": "beherrschen",
    "indicators": [...]
  }
]
```

#### 3. Submit Survey

**Endpoint:** `POST /submit_survey`

**Purpose:** Save user competency scores and generate LLM feedback

**Request:**
```json
{
  "organization_id": 123,
  "full_name": "John Doe",
  "username": "se_survey_user_456",
  "tasks_responsibilities": {...},
  "selected_roles": [
    {"id": 1, "name": "Systems Engineer"}
  ],
  "competency_scores": [
    {"competencyId": 1, "score": 4},
    {"competencyId": 5, "score": 2},
    {"competencyId": 7, "score": 6}
    // ... for all assessed competencies
  ],
  "survey_type": "known_roles"
}
```

**Backend Logic:**
```python
@main.route('/submit_survey', methods=['POST'])
def submit_survey():
    data = request.json

    # 1. Create or get AppUser
    user = AppUser.query.filter_by(
        username=data['username'],
        organization_id=data['organization_id']
    ).first()

    if not user:
        user = AppUser(
            username=data['username'],
            name=data['full_name'],
            organization_id=data['organization_id'],
            tasks_responsibilities=data['tasks_responsibilities']
        )
        db.session.add(user)
        db.session.flush()

    # 2. Save competency scores
    for score_data in data['competency_scores']:
        result = UserCompetencySurveyResults(
            user_id=user.id,
            organization_id=data['organization_id'],
            competency_id=score_data['competencyId'],
            score=score_data['score']
        )
        db.session.add(result)

    # 3. Save user-role associations (for known_roles)
    if data['survey_type'] == 'known_roles':
        for role in data['selected_roles']:
            user_role = UserRoleCluster(
                user_id=user.id,
                role_cluster_id=role['id']
            )
            db.session.add(user_role)

    # 4. Generate LLM feedback
    feedback = generate_feedback_with_llm(
        user_id=user.id,
        organization_id=data['organization_id'],
        competency_scores=data['competency_scores']
    )

    # 5. Save feedback
    survey_feedback = UserCompetencySurveyFeedback(
        user_id=user.id,
        organization_id=data['organization_id'],
        feedback=feedback
    )
    db.session.add(survey_feedback)

    db.session.commit()

    return jsonify({"message": "Survey submitted successfully"}), 200
```

#### 4. Get User Competency Results

**Endpoint:** `GET /get_user_competency_results`

**Purpose:** Retrieve user scores, required scores, and LLM feedback

**Query Parameters:**
```
username=se_survey_user_456
organization_id=123
survey_type=known_roles
```

**Backend Logic:**
```python
@main.route('/get_user_competency_results', methods=['GET'])
def get_user_competency_results():
    username = request.args.get('username')
    organization_id = request.args.get('organization_id')
    survey_type = request.args.get('survey_type')

    # Get user
    user = AppUser.query.filter_by(
        username=username,
        organization_id=organization_id
    ).first()

    # Get user scores with competency details
    user_scores = db.session.query(
        UserCompetencySurveyResults.competency_id,
        UserCompetencySurveyResults.score,
        Competency.competency_name,
        Competency.competency_area
    ).join(
        Competency, UserCompetencySurveyResults.competency_id == Competency.id
    ).filter(
        UserCompetencySurveyResults.user_id == user.id
    ).all()

    # Format user scores
    user_scores_list = [
        {
            "competency_id": score.competency_id,
            "competency_name": score.competency_name,
            "competency_area": score.competency_area,
            "score": score.score
        }
        for score in user_scores
    ]

    # Get required scores (max_scores)
    if survey_type == 'known_roles':
        # Get user's selected roles
        user_roles = UserRoleCluster.query.filter_by(user_id=user.id).all()
        role_ids = [ur.role_cluster_id for ur in user_roles]

        # Get max required competency values for these roles
        max_scores = db.session.query(
            RoleCompetencyMatrix.competency_id,
            func.max(RoleCompetencyMatrix.role_competency_value).label('max_score')
        ).filter(
            RoleCompetencyMatrix.role_cluster_id.in_(role_ids),
            RoleCompetencyMatrix.organization_id == organization_id
        ).group_by(
            RoleCompetencyMatrix.competency_id
        ).all()

        max_scores_list = [
            {
                "competency_id": score.competency_id,
                "max_score": score.max_score
            }
            for score in max_scores
        ]

    # Get feedback
    feedback = UserCompetencySurveyFeedback.query.filter_by(
        user_id=user.id,
        organization_id=organization_id
    ).first()

    feedback_list = feedback.feedback if feedback else []

    # For all_roles: find most similar role
    most_similar_role = []
    if survey_type == 'all_roles':
        most_similar_role = find_most_similar_role_cluster(
            user_id=user.id,
            organization_id=organization_id
        )

    return jsonify({
        "user_scores": user_scores_list,
        "max_scores": max_scores_list,
        "feedback_list": feedback_list,
        "most_similar_role": most_similar_role
    })
```

**Response:**
```json
{
  "user_scores": [
    {
      "competency_id": 1,
      "competency_name": "Systems Thinking",
      "competency_area": "Core",
      "score": 4
    },
    // ... all user scores
  ],
  "max_scores": [
    {
      "competency_id": 1,
      "max_score": 6
    },
    // ... all required scores
  ],
  "feedback_list": [
    {
      "competency_area": "Core",
      "feedbacks": [
        {
          "competency_name": "Systems Thinking",
          "user_strengths": "You demonstrate strong systems thinking...",
          "improvement_areas": "To reach mastery level, focus on..."
        }
      ]
    },
    // ... grouped by competency area
  ],
  "most_similar_role": [
    {
      "id": 6,
      "role_cluster_name": "System engineer"
    }
  ]
}
```

---

## Key Design Patterns in Derik's Implementation

### 1. **Always Assess All Competencies**
- For `known_roles`: All 16 competencies assessed
- For `unknown_roles`: All 16 competencies assessed
- For `all_roles`: All 16 competencies assessed
- **No filtering** based on required competencies

### 2. **Competency Indicator System**
- Each competency has 4 levels (kennen, verstehen, anwenden, beherrschen)
- Each level has 3 indicators
- Total: 12 indicators per competency × 16 competencies = 192 indicators

### 3. **Score Calculation**
- User selects groups (can select multiple)
- Score = MAX(selected groups)
- Mapping: Group 1→1, Group 2→2, Group 3→4, Group 4→6

### 4. **LLM Feedback Generation**
- Called during survey submission
- Compares user scores vs. required scores
- Generates personalized feedback per competency
- Groups feedback by competency area

### 5. **Radar Chart Visualization**
- 2-axis comparison: User vs. Required
- Filterable by competency area
- All competencies shown (no hiding based on relevance)

---

## Differences: Derik's vs. Phase 2 Requirements

| Aspect | Derik's Implementation | Phase 2 Requirements |
|--------|------------------------|----------------------|
| **Number of Questions** | Always 16 (all competencies) | Dynamic (only necessary competencies) |
| **Competency Filtering** | None - assess all | Filter out competencies with required_level = 0 |
| **Survey Length** | Fixed (always 16 questions) | Variable (3-12 questions typically) |
| **Role Selection** | During survey start | Task 1: Before assessment |
| **Results Display** | All 16 competencies on radar | Only assessed competencies |
| **Learning Objectives** | Not implemented | Task 3: LLM-generated org-wide |
| **Admin View** | Not implemented | Task 3: Aggregate all employee results |
| **User Types** | Single flow for all | Admin vs. Employee workflows |

---

## What to Keep from Derik's Implementation

### ✓ Keep These Patterns:

1. **Competency Indicator Card System**
   - 4-level grouping (kennen, verstehen, anwenden, beherrschen)
   - Card-based selection UI
   - Multi-select capability

2. **Sequential One-at-a-Time Presentation**
   - One competency per screen
   - Progress indicator
   - Back/Next navigation

3. **Score Mapping Logic**
   ```
   Group 1 → Score 1
   Group 2 → Score 2
   Group 3 → Score 4
   Group 4 → Score 6
   Group 5 (None) → Score 0
   MAX(selected groups) = final score
   ```

4. **Radar Chart Visualization**
   - User vs. Required comparison
   - Filterable by competency area
   - Export to PDF

5. **LLM Feedback Structure**
   - Grouped by competency area
   - Strengths + Improvement areas per competency

6. **Backend Endpoints Pattern**
   - `get_required_competencies_for_roles`
   - `get_competency_indicators_for_competency/<id>`
   - `submit_survey`
   - `get_user_competency_results`

---

## What to Change for Phase 2

### ✗ Changes Needed:

1. **Dynamic Competency Filtering**
   - **Current:** Always fetch all 16 competencies
   - **Phase 2:** Only fetch competencies where `required_level > 0`

   ```python
   # Current (Derik)
   competencies = Competency.query.all()

   # Phase 2
   competencies = (
       db.session.query(RoleCompetencyMatrix)
       .filter(
           RoleCompetencyMatrix.role_cluster_id.in_(role_ids),
           RoleCompetencyMatrix.organization_id == organization_id,
           RoleCompetencyMatrix.role_competency_value > 0  # FILTER OUT 0
       )
       .all()
   )
   ```

2. **Separate Task 1: Role Selection + Competency Display**
   - **Current:** Role selection during survey start, no competency preview
   - **Phase 2:** Dedicated Task 1 view showing:
     - Identified roles from Phase 1
     - Grid-based role selection
     - **NEW:** Display calculated necessary competencies before assessment

3. **Admin Workflow (Task 3)**
   - **Current:** Not implemented
   - **Phase 2:** Add admin dashboard to:
     - View all employee assessments
     - Aggregate competency gaps
     - Generate organization-wide learning objectives

4. **User Type Distinction**
   - **Current:** All users follow same flow
   - **Phase 2:**
     - Employees: Task 1 → Task 2 → END
     - Admins: Task 1 → Task 2 → Task 3 → Export

5. **Results Page Enhancements**
   - **Current:** Show all 16 competencies on radar
   - **Phase 2:**
     - Only show assessed competencies
     - Clear "Strengths" vs. "Gaps" sections
     - Highlight high-priority development areas

---

## Implementation Recommendations for Phase 2

### Reuse Derik's Code:

1. **`CompetencySurvey.vue`** - Reuse with modifications:
   - Keep: Card-based UI, navigation, score mapping
   - Change: Filter competencies before rendering
   - Add: Display required level for each competency

2. **`SurveyResults.vue`** - Reuse with enhancements:
   - Keep: Radar chart, feedback display, PDF export
   - Change: Only show assessed competencies on chart
   - Add: Strengths/Gaps sections

3. **Backend Routes** - Adapt existing patterns:
   - Keep: Route structure and logic flow
   - Change: Add filtering logic for required_level > 0
   - Add: New admin routes for Task 3

### Build New Components:

1. **`Phase2RoleSelection.vue`** (Task 1)
   - Grid-based role selection from Phase 1 data
   - Display necessary competencies after selection

2. **`Phase2AdminDashboard.vue`** (Task 3)
   - Employee assessment summary
   - Aggregation statistics
   - Learning objectives display

3. **`Phase2LearningObjectives.vue`** (Task 3)
   - Display LLM-generated objectives
   - Implementation roadmap
   - Export functionality

---

## Competency Indicator Levels - Translation

| English | German | Level Value | Score Mapping |
|---------|--------|-------------|---------------|
| Know | Kennen | 1 | Group 1 → Score 1 |
| Understand | Verstehen | 2 | Group 2 → Score 2 |
| Apply | Anwenden | 4 | Group 3 → Score 4 |
| Master | Beherrschen | 6 | Group 4 → Score 6 |
| None | Keine | 0 | Group 5 → Score 0 |

---

## Summary

Derik's implementation provides a **solid foundation** for Phase 2, with excellent UI/UX patterns and a working competency assessment flow. The main changes needed are:

1. **Dynamic filtering** to reduce survey length
2. **Task 1 separation** with competency preview
3. **Admin workflow** for organization-wide learning objectives

By adapting Derik's proven patterns and adding Phase 2-specific features, we can build an efficient, user-friendly competency assessment system.

---

**Document Status:** COMPLETE ✓
**Last Updated:** 2025-10-20
**Ready for:** Phase 2 Implementation Planning
