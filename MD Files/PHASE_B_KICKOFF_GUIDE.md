# Phase B Kickoff Guide - Phase 2 Task 2 Implementation

**Created:** 2025-10-20
**Purpose:** Quick-start guide for implementing Phase 2 Task 2 (Dynamic Competency Assessment)
**Prerequisites:** Phase A (Task 1) completed ✅

---

## 🎯 Quick Start Instructions for Next Session

### Step 1: Read Required Context (5-10 minutes)

**In this exact order:**

1. **SESSION_HANDOVER.md** (Lines 1-160)
   - Read "SESSION 2025-10-20 (Part 3): Phase 2 Task 1 Implementation COMPLETE"
   - Focus on: Backend Implementation, Frontend Implementation, Implementation Patterns

2. **PHASE2_IMPLEMENTATION_REFERENCE.md** (Focus on Task 2 section)
   - Phase B: Task 2 - Identify Competency Gaps
   - Backend endpoints specification
   - Frontend component requirements

3. **DERIK_PHASE2_ANALYSIS.md** (Focus on CompetencySurvey.vue)
   - Card-based UI pattern
   - Score mapping logic (groups → competency levels)
   - Survey submission flow

### Step 2: Verify System Status

```bash
# Check servers are running
curl http://localhost:5003/api/phase2/identified-roles/24
# Should return: {"success":true,"count":73,...}

curl http://localhost:5173
# Should return: Vite dev server
```

### Step 3: Start Implementation

```
Start with: "Continue with Phase B implementation based on SESSION_HANDOVER.md and PHASE_B_KICKOFF_GUIDE.md"
```

---

## ✅ What Was Completed in Phase A

### Backend (Flask) - 2 Endpoints Working

1. **GET /api/phase2/identified-roles/<org_id>** (`routes.py:3249-3297`)
   - Returns Phase 1 roles with `participating_in_training = True`
   - Tested: Org 24 → 73 roles ✅

2. **POST /api/phase2/calculate-competencies** (`routes.py:3300-3440`)
   - Calculates necessary competencies (filters `role_competency_value > 0`)
   - Tested: 3 roles → 16 competencies ✅

### Frontend (Vue 3 + Element Plus) - 3 Files Created

1. **src/frontend/src/api/phase2.js** - API module ✅
2. **src/frontend/src/components/phase2/Phase2RoleSelection.vue** - Grid layout ✅
3. **src/frontend/src/components/phase2/Phase2NecessaryCompetencies.vue** - Display ✅

### Key Patterns Established

**API Response Format:**
```javascript
{
  success: true,
  count: 16,
  competencies: [
    {
      competencyId: 1,
      competencyName: "Systems Thinking",
      competencyArea: "Core",
      requiredLevel: 4,
      description: "...",
      whyItMatters: "..."
    }
    // ...
  ],
  selectedRoles: [...]
}
```

**Component Communication:**
```vue
<!-- Parent to child -->
<Phase2RoleSelection :organizationId="24" @next="handleNext" />

<!-- Child emits -->
emit('next', { competencies, selectedRoles, organizationId })
```

---

## 🚀 Phase B Implementation Tasks

### Task Overview

**Goal:** Implement dynamic competency assessment where employees only answer questions for necessary competencies (not all 16).

**Workflow:**
```
Phase2NecessaryCompetencies (Task 1 complete)
    ↓ "Start Assessment" button clicked
Phase2CompetencyAssessment (NEW - Task 2)
    ↓ User answers questions for N competencies
Phase2AssessmentResults (NEW - Task 2)
    ↓ Shows current vs. required levels + gaps
```

---

## 📋 Implementation Checklist

### Backend (Flask) - Estimated 300-400 lines

**File:** `src/competency_assessor/app/routes.py`

#### 1. Create Assessment Initialization Endpoint

```python
@main.route('/api/phase2/start-assessment', methods=['POST'])
def start_phase2_assessment():
    """
    Initialize Phase 2 competency assessment

    Request:
    {
        "org_id": 24,
        "employee_name": "John Doe",
        "role_ids": [101, 102],
        "competencies": [...],  # From Task 1 calculation
        "assessment_type": "employee"  # or "admin"
    }

    Response:
    {
        "success": true,
        "assessment_id": 456,
        "competencies_to_assess": 12,  # Filtered count
        "estimated_time": 24  # minutes
    }
    """
    # 1. Create CompetencyAssessment record
    # 2. Store competencies to assess
    # 3. Return assessment_id for tracking
```

#### 2. Create Dynamic Questions Endpoint

```python
@main.route('/api/phase2/assessment-questions/<int:assessment_id>', methods=['GET'])
def get_phase2_assessment_questions(assessment_id):
    """
    Get competency indicators for dynamic assessment
    Only returns questions for necessary competencies

    Response:
    {
        "success": true,
        "assessment_id": 456,
        "questions": [
            {
                "competency_id": 1,
                "competency_name": "Systems Thinking",
                "required_level": 4,
                "indicators_by_level": [
                    {
                        "level": 1,
                        "level_name": "Know",
                        "indicators": [
                            {
                                "id": 123,
                                "indicator_en": "...",
                                "indicator_de": "..."
                            }
                        ]
                    }
                ]
            }
        ]
    }
    """
    # 1. Get assessment record
    # 2. For each competency, fetch indicators from competency_indicators table
    # 3. Group by level (1, 2, 4, 6)
    # 4. Return structured questions
```

#### 3. Create Submission & Gap Calculation Endpoint

```python
@main.route('/api/phase2/submit-assessment', methods=['POST'])
def submit_phase2_assessment():
    """
    Submit assessment answers and calculate gaps

    Request:
    {
        "assessment_id": 456,
        "answers": [
            {
                "competency_id": 1,
                "selected_groups": [1, 2, 3],  # User selected groups
                "current_level": 4  # Calculated max level
            }
        ]
    }

    Response:
    {
        "success": true,
        "results": {
            "gaps": [
                {
                    "competency_id": 1,
                    "competency_name": "Systems Thinking",
                    "required_level": 6,
                    "current_level": 4,
                    "gap": 2,
                    "status": "gap"  # or "met" or "exceeded"
                }
            ],
            "summary": {
                "total_competencies": 12,
                "gaps_found": 5,
                "requirements_met": 7
            }
        },
        "llm_feedback": "..."  # Optional AI-generated feedback
    }
    """
    # 1. Save answers to user_competency_survey_results table
    # 2. Calculate gaps: required_level - current_level
    # 3. Generate LLM feedback with role context
    # 4. Return comprehensive results
```

---

### Frontend (Vue 3 + Element Plus) - Estimated 600-800 lines

**Directory:** `src/frontend/src/components/phase2/`

#### 1. Update API Module

**File:** `src/frontend/src/api/phase2.js`

Add to `phase2Task2Api`:
```javascript
export const phase2Task2Api = {
  startAssessment: async (orgId, employeeName, roleIds, competencies) => {
    const response = await axiosInstance.post('/api/phase2/start-assessment', {
      org_id: orgId,
      employee_name: employeeName,
      role_ids: roleIds,
      competencies
    });
    return response.data;
  },

  getQuestions: async (assessmentId) => {
    const response = await axiosInstance.get(`/api/phase2/assessment-questions/${assessmentId}`);
    return response.data;
  },

  submitAssessment: async (assessmentId, answers) => {
    const response = await axiosInstance.post('/api/phase2/submit-assessment', {
      assessment_id: assessmentId,
      answers
    });
    return response.data;
  }
};
```

#### 2. Create Assessment Component

**File:** `Phase2CompetencyAssessment.vue`

**Key features (adapt from Derik's CompetencySurvey.vue):**
- Card-based UI for indicator groups (Group 1, 2, 3, 4, 5)
- One question per competency (only necessary competencies)
- Progress indicator (Question X of Y)
- Back/Next navigation
- Multi-select groups (can select multiple)
- Group 5 = "None of these" (deselects others)
- Submit modal at end
- Score mapping: Group 1=1, Group 2=2, Group 3=4, Group 4=6, Group 5=0

**Template structure:**
```vue
<template>
  <el-card>
    <!-- Progress -->
    <div>Question {{ currentIndex + 1 }} of {{ totalQuestions }}</div>

    <!-- Current competency -->
    <h2>{{ currentCompetency.name }}</h2>
    <p>To which of these groups do you identify yourself?</p>

    <!-- Indicator cards (5 groups) -->
    <el-row :gutter="20">
      <el-col v-for="group in indicatorGroups" :span="4">
        <el-card
          :class="{ selected: isSelected(group.number) }"
          @click="toggleGroup(group.number)"
        >
          <h3>Group {{ group.number }}</h3>
          <div v-for="indicator in group.indicators">
            {{ indicator.indicator_en }}
          </div>
        </el-card>
      </el-col>

      <!-- Group 5: None of these -->
      <el-col :span="4">
        <el-card
          :class="{ selected: selectedGroups.includes(5) }"
          @click="selectNone"
        >
          <h3>Group 5</h3>
          <p>You do not see yourself in any of these groups.</p>
        </el-card>
      </el-col>
    </el-row>

    <!-- Navigation -->
    <el-button @click="goBack">Back</el-button>
    <el-button @click="goNext" type="primary">Next</el-button>
  </el-card>
</template>
```

#### 3. Create Results Component

**File:** `Phase2AssessmentResults.vue`

**Key features:**
- Display gaps table (competency, required, current, gap, status)
- Color coding: Red (gap), Green (met), Blue (exceeded)
- Summary statistics (total, gaps, met)
- Radar chart (optional - compare required vs. current)
- LLM-generated feedback section
- Download PDF / Print buttons
- "Continue to Task 3" button (Admin only)

---

## 🔧 Code Examples & Patterns

### Score Mapping (Derik's Pattern)

```javascript
const calculateScore = (selectedGroups) => {
  const maxGroup = Math.max(...selectedGroups);

  if (maxGroup === 1) return 1;  // kennen (know)
  else if (maxGroup === 2) return 2;  // verstehen (understand)
  else if (maxGroup === 3) return 4;  // anwenden (apply)
  else if (maxGroup === 4) return 6;  // beherrschen (master)
  else return 0;  // none of these
};
```

### Gap Calculation

```javascript
const calculateGaps = (competencies, answers) => {
  return competencies.map(comp => {
    const answer = answers.find(a => a.competency_id === comp.competencyId);
    const currentLevel = answer ? answer.current_level : 0;
    const gap = comp.requiredLevel - currentLevel;

    return {
      ...comp,
      currentLevel,
      gap,
      status: gap > 0 ? 'gap' : gap === 0 ? 'met' : 'exceeded'
    };
  });
};
```

---

## 🧪 Testing Plan

### Backend Testing

**Test Sequence:**
```bash
# 1. Start assessment
curl -X POST http://localhost:5003/api/phase2/start-assessment \
  -H "Content-Type: application/json" \
  -d '{"org_id": 24, "employee_name": "Test User", "role_ids": [86, 88]}'
# Expected: { "success": true, "assessment_id": 456 }

# 2. Get questions
curl http://localhost:5003/api/phase2/assessment-questions/456
# Expected: { "questions": [...] }

# 3. Submit assessment
curl -X POST http://localhost:5003/api/phase2/submit-assessment \
  -H "Content-Type: application/json" \
  -d '{"assessment_id": 456, "answers": [...]}'
# Expected: { "success": true, "results": { "gaps": [...] } }
```

### Frontend Testing

1. **Component isolation:** Test Phase2CompetencyAssessment with mock data
2. **Integration:** Test full flow (Task 1 → Task 2)
3. **Edge cases:**
   - All competencies have gaps
   - No gaps (all requirements met)
   - User selects Group 5 (none of these) for all

---

## 📊 Database Tables Used

### Read Operations
- `competency` - Get competency details
- `competency_indicators` - Get indicators for questions
- `role_competency_matrix` - Get required levels (already in Task 1 response)

### Write Operations
- `competency_assessment` - Store assessment metadata (may need new table)
- `user_competency_survey_results` - Store answers

### SQL Example (Get Indicators)
```sql
SELECT
    ci.id,
    ci.level,
    ci.indicator_en,
    ci.indicator_de
FROM competency_indicators ci
WHERE ci.competency_id = ?
ORDER BY
    CASE ci.level
        WHEN 'kennen' THEN 1
        WHEN 'verstehen' THEN 2
        WHEN 'anwenden' THEN 3
        WHEN 'beherrschen' THEN 4
    END;
```

---

## 🎨 UI Design Specifications

### Card Layout (Derik's Pattern)
- **Grid:** 5 columns (Groups 1-5)
- **Card style:** Dark background (#2e2e2e), white text
- **Selected:** Green border (#4CAF50), glow effect
- **Hover:** Scale up, shadow effect
- **Separator lines:** Between indicators, green (#4CAF50)

### Element Plus Equivalents
- `v-card` → `<el-card>`
- `v-btn` → `<el-button>`
- `v-progress-circular` → `<el-progress type="circle">`
- `v-dialog` → `<el-dialog>`

---

## ⚠️ Important Notes

### 1. Don't Reinvent the Wheel
- **Reuse:** Derik's score mapping logic (groups → levels)
- **Adapt:** UI from Vuetify to Element Plus
- **Keep:** Card-based visual design

### 2. Database Compatibility
- Use existing tables where possible
- May need new table for assessment tracking
- Check if `user_competency_survey_results` needs modifications

### 3. LLM Feedback Enhancement
- Add role context to prompt
- Include organization-specific information
- Reference specific gaps in feedback

### 4. Error Handling
- Validate assessment exists before questions
- Handle missing indicators gracefully
- Provide fallback if LLM fails

---

## 📈 Success Criteria

### Must Have
- [x] Backend: 3 endpoints working (start, questions, submit)
- [x] Frontend: Phase2CompetencyAssessment.vue functional
- [x] Frontend: Phase2AssessmentResults.vue displays gaps
- [x] Integration: Full flow working (Task 1 → Task 2)
- [x] Testing: All endpoints tested with real data

### Nice to Have
- [ ] Radar chart visualization
- [ ] PDF export
- [ ] Enhanced LLM feedback
- [ ] Progress persistence (save/resume)

---

## 🚧 Known Challenges & Solutions

### Challenge 1: Indicator Grouping
**Problem:** Competency_indicators table has 4 level names (kennen, verstehen, anwenden, beherrschen)
**Solution:** Map to 4 groups (1-4), plus Group 5 (none)

### Challenge 2: Dynamic Question Count
**Problem:** Different roles = different competency counts
**Solution:** Use Task 1 calculation result as source of truth

### Challenge 3: Gap Calculation Edge Cases
**Problem:** What if current > required?
**Solution:** Allow "exceeded" status (positive outcome)

---

## 📞 Quick Reference

**Database Credentials:**
```
Host: localhost:5432
Database: competency_assessment
User: ma0349
Password: MA0349_2025
```

**Servers:**
```
Flask: http://localhost:5003
Frontend: http://localhost:5173
```

**Test Organization:**
```
Org ID: 24
Roles: 73 (with participating_in_training=True)
```

**Files to Modify:**
```
Backend: src/competency_assessor/app/routes.py (add after line 3440)
Frontend API: src/frontend/src/api/phase2.js
Frontend Components: src/frontend/src/components/phase2/
```

---

## 🎯 Next Session Command

When starting next session, say:

```
Continue with Phase B implementation based on SESSION_HANDOVER.md and PHASE_B_KICKOFF_GUIDE.md.
Start by creating the backend endpoint: POST /api/phase2/start-assessment
```

---

**End of Phase B Kickoff Guide**
**Ready to implement!** 🚀
