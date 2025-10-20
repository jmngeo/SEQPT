# Phase 1 Task 2: SE Role Identification - Comprehensive Test Cases

**Date:** 2025-10-18
**Purpose:** Complete testing guide for both Standard and Task-Based pathways
**Organization Test Code:** JPAWJ_ (Org ID: 24)

---

## Test Environment Setup

**URLs:**
- Frontend: http://localhost:3000
- Backend: http://127.0.0.1:5003
- Phase 1: http://localhost:3000/app/phases/1

**Test User Credentials:**
- Org Code: `JPAWJ_`
- Org ID: 24
- User ID: 30
- Role: admin

**Database:**
- PostgreSQL: `competency_assessment`
- Credentials: `ma0349:MA0349_2025@localhost:5432`

---

## Test Case 1: Standard Pathway (High Maturity - seProcessesValue >= 3)

### Prerequisites
1. Navigate to Phase 1: http://localhost:3000/app/phases/1
2. Login as admin (org code: `JPAWJ_`)

### Step 1: Complete Maturity Assessment for High Maturity

**Answer the 4 Questions:**

| Question | Answer | Value |
|----------|--------|-------|
| Q1: Rollout Scope | "Company Wide" | 3 |
| Q2: SE Processes & Roles | "Defined and Established" | 3 |
| Q3: SE Mindset | "Established" | 3 |
| Q4: Knowledge Base | "Established" | 3 |

- Click "Calculate Maturity"
- **Expected:** Maturity score ~75, Level 3-4
- **Expected:** Results display: "Defined maturity level"
- Click "Continue" to proceed to Task 2

### Step 2: Verify Standard Role Selection Pathway

**Expected Display:**
- Alert message: "Your organization has defined SE processes (Maturity Level: 3)"
- Component shows: "Standard Role Selection"
- Display shows: 14 SE role clusters grouped by category

**Categories Expected:**
1. Customer & Interfaces
2. Development & Engineering
3. Production & Operations
4. Quality & Validation
5. Management & Support

### Step 3: Select Roles and Customize Names

**Test Scenario A: Select 3 Roles Without Customization**

Select the following roles:
- ☑ System Engineer
- ☑ Specialist Developer
- ☑ Quality Engineer/Manager

Leave organization names blank (use standard names)

- Click "Continue to Target Group Size"
- **Expected:** Roles saved with `identification_method='STANDARD'`

**Test Scenario B: Select 5 Roles With Custom Names**

Select the following roles with custom names:

| Standard Role | Custom Organization Name |
|--------------|-------------------------|
| System Engineer | Software Architect |
| Specialist Developer | Senior Software Engineer |
| Project Manager | Product Lead |
| Quality Engineer/Manager | QA Lead |
| Verification and Validation (V&V) Operator | Test Engineer |

- Click "Continue to Target Group Size"
- **Expected:** 5 roles saved with customized `org_role_name` values

### Step 4: Select Target Group Size

Choose one of the following:

**Option A: Small Group (< 20 people)**
- **Expected implications:**
  - Formats: Workshop, Coaching, Mentoring
  - Approach: Direct intensive training
  - Train-the-Trainer: NO

**Option B: Medium Group (20-100 people)**
- **Expected implications:**
  - Formats: Workshop, Blended Learning, Group Projects
  - Approach: Mixed format with cohorts
  - Train-the-Trainer: Optional

**Option C: Large Group (100-500 people)** ← Recommended for testing
- **Expected implications:**
  - Formats: Blended Learning, E-Learning, Train-the-Trainer
  - Approach: Scalable formats required
  - Train-the-Trainer: YES
  - **Tag displayed:** "Train-the-Trainer Recommended"

- Click "Continue to Strategy Selection"
- **Expected:** Success message, navigation to Step 3 (Strategy Selection)

### Database Verification (Standard Pathway)

```sql
-- Check saved roles
SELECT
  id,
  org_id,
  standard_role_name,
  org_role_name,
  identification_method,
  participating_in_training
FROM phase1_roles
WHERE org_id = 24
ORDER BY id DESC LIMIT 5;

-- Expected results:
-- identification_method = 'STANDARD'
-- org_role_name = custom name OR NULL (if not customized)
-- participating_in_training = true

-- Check target group
SELECT * FROM phase1_target_group
WHERE org_id = 24
ORDER BY id DESC LIMIT 1;

-- Expected result:
-- size_range = '100-500' (or your selection)
-- size_category = 'LARGE'
-- train_the_trainer_recommended = true (for 100-500)
```

---

## Test Case 2: Task-Based Pathway (Low Maturity - seProcessesValue < 3)

### Prerequisites
1. Clear previous maturity assessment or use different test organization
2. Navigate to Phase 1

### Step 1: Complete Maturity Assessment for Low Maturity

**Answer the 4 Questions:**

| Question | Answer | Value |
|----------|--------|-------|
| Q1: Rollout Scope | "Individual Area" | 1 |
| Q2: SE Processes & Roles | "Individually Controlled" | 2 |
| Q3: SE Mindset | "Fragmented" | 2 |
| Q4: Knowledge Base | "Fragmented" | 2 |

- Click "Calculate Maturity"
- **Expected:** Maturity score ~30-40, Level 1-2
- **Expected:** Results display: "Initial" or "Developing" maturity level
- Click "Continue" to proceed to Task 2

### Step 2: Verify Task-Based Mapping Pathway

**Expected Display:**
- Alert message: "Your organization is developing SE processes (Maturity Level: 1-2)"
- Component shows: "Task-Based Role Mapping"
- Display shows: Job profile input form
- Info alert: "Add all job profiles that will be affected by the SE training program"

### Step 3: Add Job Profiles

**IMPORTANT:** All three task categories (Responsible For, Supporting, Designing/Improving) are MANDATORY.
The backend LLM requires meaningful content in ALL THREE fields, or it will reject the request with a 400 error.

**Job Profile #1: Senior Software Developer**

```
Job Title: Senior Software Developer

Responsible For: (REQUIRED - 2-3 tasks minimum)
Developing embedded software modules for automotive control systems
Writing unit tests and integration tests for software components
Creating technical documentation for software designs
Implementing software modules according to system specifications
Debugging and fixing software defects

Supporting: (REQUIRED - 1-2 tasks minimum)
Code reviews for junior developers
Helping team members troubleshoot technical issues
Mentoring junior engineers in software best practices
Supporting integration testing activities

Designing/Improving: (REQUIRED - 1-2 tasks minimum)
Software architecture for control modules
Design patterns and coding standards
Software development processes and workflows
Continuous integration and deployment pipelines

Department: Engineering
```

**Expected Role Mapping:**
- **Suggested Role:** Specialist Developer
- **Confidence:** 75-90%
- **Rationale:** Strong development focus with responsible tasks

---

**Job Profile #2: Systems Integration Engineer**

```
Job Title: Systems Integration Engineer

Responsible For:
Integrating software and hardware components into complete systems
Coordinating interfaces between different system modules
Defining integration test procedures and executing tests
Managing system-level requirements and specifications
Ensuring compatibility across system boundaries

Supporting:
System architecture reviews
Requirements analysis and decomposition
Stakeholder communication and coordination
Risk assessment for integration activities

Designing/Improving:
System integration strategies and approaches
Interface specifications between components
Integration testing frameworks
System verification procedures

Department: Engineering
```

**Expected Role Mapping:**
- **Suggested Role:** System Engineer
- **Confidence:** 80-95%
- **Rationale:** System-level integration and coordination focus

---

**Job Profile #3: Quality Assurance Specialist**

```
Job Title: Quality Assurance Specialist

Responsible For:
Developing and executing test plans for software and systems
Identifying and documenting software defects
Ensuring compliance with quality standards and regulations
Performing regression testing on software releases
Managing defect tracking and resolution processes

Supporting:
Process improvement initiatives
Root cause analysis of quality issues
Training team members on testing procedures
Quality metrics collection and reporting

Designing/Improving:
Quality assurance processes and procedures
Test automation frameworks
Quality metrics and KPIs
Continuous improvement initiatives

Department: Quality
```

**Expected Role Mapping:**
- **Suggested Role:** Quality Engineer/Manager
- **Confidence:** 85-95%
- **Rationale:** Quality focus with testing and process improvement

---

**Job Profile #4: Technical Project Lead**

```
Job Title: Technical Project Lead

Responsible For:
Planning and coordinating technical project activities
Monitoring project progress and managing resources
Tracking project objectives and deliverables
Managing project risks and issues
Coordinating between technical teams and stakeholders

Supporting:
Technical decision-making processes
Resource allocation and scheduling
Stakeholder communication and reporting
Team performance management

Designing/Improving:
Project management processes and templates
Risk management strategies
Communication workflows
Team collaboration practices

Department: Management
```

**Expected Role Mapping:**
- **Suggested Role:** Project Manager
- **Confidence:** 80-90%
- **Rationale:** Project coordination and management focus

---

**Job Profile #5: Hardware Design Engineer**

```
Job Title: Hardware Design Engineer

Responsible For:
Designing electronic circuits and hardware components
Creating schematics and PCB layouts
Selecting components and materials for hardware designs
Conducting hardware testing and validation
Producing hardware documentation and specifications

Supporting:
System architecture development
Design reviews and technical assessments
Prototyping and proof-of-concept activities
Troubleshooting hardware issues

Designing/Improving:
Hardware design methodologies
Component selection criteria
Testing procedures for hardware validation
Design tools and workflows

Department: Engineering
```

**Expected Role Mapping:**
- **Suggested Role:** Specialist Developer
- **Confidence:** 70-85%
- **Rationale:** Specialized development focus (hardware rather than software)

---

### Step 4: Map Profiles to Roles

- Click "Map to SE Roles"
- **Expected:** Loading indicator appears
- **Expected:** AI processing time: 10-30 seconds (5-6 seconds per profile)
- **Expected:** Success alert: "AI analysis complete! Review the suggested role mappings below."

### Step 5: Review and Adjust Mappings

For each profile, verify:
- **Suggested Role** matches expected role
- **Confidence Score** displayed as color-coded tag:
  - Green (success): 80-100%
  - Yellow (warning): 65-79%
  - Red (danger): <65%
- **Role Description** displayed
- **Organization Name** pre-filled with job title

**Adjustment Options:**
1. **Keep Suggested Role:** Leave as-is
2. **Change Role:** Select different role from dropdown
3. **Customize Name:** Edit organization-specific role name

**Example Customizations:**
- "Senior Software Developer" → "Software Engineer Level 3"
- "Systems Integration Engineer" → "Integration Architect"
- "Quality Assurance Specialist" → "QA Engineer"

### Step 6: Save and Continue

- Click "Save and Continue"
- **Expected:** Loading indicator
- **Expected:** Success message with role count
- **Expected:** Automatic navigation to Target Group Size selection

### Step 7: Select Target Group Size

Choose: **Medium Group (20-100 people)**
- **Expected implications:**
  - Formats: Workshop, Blended Learning, Group Projects
  - Approach: Mixed format with cohorts
  - Train-the-Trainer: Optional

- Click "Continue to Strategy Selection"
- **Expected:** Success message
- **Expected:** Navigation to Step 3 (Strategy Selection)

### Database Verification (Task-Based Pathway)

```sql
-- Check saved roles
SELECT
  id,
  org_id,
  standard_role_name,
  org_role_name,
  job_description,
  identification_method,
  confidence_score,
  participating_in_training
FROM phase1_roles
WHERE org_id = 24
ORDER BY id DESC LIMIT 5;

-- Expected results:
-- identification_method = 'TASK_BASED'
-- job_description = original job title
-- main_tasks = JSON with responsible_for, supporting, designing arrays
-- iso_processes = JSON with process mappings from LLM
-- confidence_score = 70-95
-- org_role_name = customized name OR job title

-- Check process mappings
SELECT * FROM unknown_role_process_matrix
WHERE org_id = 24
ORDER BY id DESC LIMIT 10;

-- Expected: Process involvement values for each job profile

-- Check target group
SELECT * FROM phase1_target_group
WHERE org_id = 24
ORDER BY id DESC LIMIT 1;
```

---

## Test Case 3: Navigation Testing

### Test Back Button Navigation

**From Task 2 to Task 1:**
1. Complete maturity assessment (either pathway)
2. Navigate to Task 2 (Role Identification)
3. **Click "Back to Maturity Assessment"** button
4. **Expected:** Navigate back to Task 1 (Maturity Assessment)
5. **Expected:** Previous maturity results still displayed
6. **Expected:** Can retake assessment with different answers
7. Retake with different `seProcessesValue`:
   - If was >=3, change to <3 (or vice versa)
8. Click "Continue"
9. **Expected:** Navigate to Task 2 with NEW pathway based on new maturity
10. **Verify:** Pathway changed correctly

**Example:**
- First time: seProcessesValue = 4 → Standard Pathway
- Retake: seProcessesValue = 1 → Task-Based Pathway ✓

**From Target Group back to Role Selection:**
1. Complete role selection
2. Navigate to Target Group Size step
3. **Click "Back"** button
4. **Expected:** Return to role selection step (Step 1 of Task 2)
5. **Expected:** Previous selections preserved
6. Can modify role selection
7. Continue again to Target Group

---

## Test Case 4: Edge Cases and Error Handling

### Scenario A: No Roles Selected (Standard Pathway)
1. Navigate to Standard Role Selection
2. Don't select any roles
3. Click "Continue to Target Group Size"
4. **Expected:** Error alert: "Please select at least one role to continue."
5. **Expected:** Button remains disabled until at least 1 role selected

### Scenario B: Empty Job Profile (Task-Based Pathway)
1. Navigate to Task-Based Mapping
2. Leave job title empty
3. Fill in some tasks
4. Click "Map to SE Roles"
5. **Expected:** Profile skipped, only profiles with titles processed

### Scenario C: Incomplete Tasks Entered (Task-Based Pathway)
1. Enter job title: "Test Role"
2. Fill in "Responsible For" and "Supporting" but leave "Designing/Improving" empty
3. **Expected:** "Map to SE Roles" button is DISABLED (all three fields required)
4. Fill in "Designing/Improving" with at least 1 task
5. **Expected:** "Map to SE Roles" button becomes ENABLED

**IMPORTANT:** All three task categories (Responsible For, Supporting, Designing/Improving) are MANDATORY.
The backend LLM validation requires meaningful content in ALL THREE categories or it returns 400 error.

### Scenario D: No Target Group Selected
1. Complete role selection
2. Navigate to Target Group Size
3. Don't select any option
4. Click "Continue to Strategy Selection"
5. **Expected:** Error alert: "Please select a target group size to continue."

### Scenario E: Backend API Failure
1. Stop Flask backend
2. Try to save roles
3. **Expected:** Error alert: "Failed to save roles. Please try again."
4. **Expected:** No navigation occurs
5. **Expected:** Data preserved in form

---

## Test Case 5: Data Persistence and History

### Test Multiple Assessments
1. Complete full Phase 1 Task 2 (either pathway)
2. Navigate away from Phase 1
3. Return to Phase 1
4. **Expected:** Load latest assessment automatically
5. **Expected:** Can view results from Task 1 and Task 2
6. Retake maturity assessment with different answers
7. Complete Task 2 again
8. **Expected:** New records created (history tracking)
9. Check database for multiple entries

```sql
-- Verify history tracking
SELECT
  maturity_id,
  COUNT(*) as roles_count,
  identification_method,
  created_at
FROM phase1_roles
WHERE org_id = 24
GROUP BY maturity_id, identification_method, created_at
ORDER BY created_at DESC;

-- Expected: Multiple entries with different maturity_id values
```

---

## Additional Test Scenarios

### Test Scenario: Mixed Job Profiles

Add 6 diverse job profiles covering all SE role categories:

1. **Customer Interface Representative**
2. **Requirements Engineer**
3. **Production Coordinator**
4. **Service Technician**
5. **Process Manager**
6. **Innovation Manager**

(Full job descriptions available in seRoleClusters.js comments)

### Test Scenario: Select All Roles (Standard Pathway)

1. Navigate to Standard Role Selection
2. Click "Select All" button
3. **Expected:** All 14 roles checked
4. Customize 3-4 names
5. Click "Deselect All"
6. **Expected:** All roles unchecked, custom names cleared
7. Manually select 5-7 roles
8. Continue to completion

---

## Success Criteria

### Standard Pathway
- ✅ Correct pathway determination (seProcessesValue >= 3)
- ✅ All 14 roles displayed and grouped
- ✅ Select All / Deselect All works
- ✅ Custom names saved correctly
- ✅ Roles saved with `identification_method='STANDARD'`
- ✅ Navigation to Target Group works
- ✅ Back button returns to maturity assessment

### Task-Based Pathway
- ✅ Correct pathway determination (seProcessesValue < 3)
- ✅ Job profile input form displayed
- ✅ Add/Remove profiles works
- ✅ LLM mapping completes successfully
- ✅ Suggested roles are reasonable
- ✅ Confidence scores displayed
- ✅ Can adjust suggested roles
- ✅ Roles saved with `identification_method='TASK_BASED'`
- ✅ Navigation works correctly
- ✅ Back button returns to maturity assessment

### Target Group Selection
- ✅ 5 size options displayed
- ✅ Train-the-Trainer tag appears for large groups
- ✅ Implications displayed correctly
- ✅ Selection saved to database
- ✅ Navigation to Task 3 works

### Navigation
- ✅ Back button from Task 2 returns to Task 1
- ✅ Can retake maturity assessment
- ✅ Pathway changes based on new maturity
- ✅ Auto-navigation to next step works
- ✅ Data persistence across navigation

---

## Troubleshooting

### Issue: LLM Mapping Fails
- **Check:** Flask backend is running
- **Check:** OpenAI API key is set in `.env`
- **Check:** `/findProcesses` endpoint is accessible
- **Check:** Console for error messages

### Issue: Styles Look Wrong
- **Check:** Element Plus is properly loaded
- **Check:** No Vuetify conflicts
- **Check:** Browser cache cleared

### Issue: Navigation Not Working
- **Check:** PhaseOne.vue `previousStep()` function
- **Check:** Maturity data is available
- **Check:** Console for errors

---

**End of Test Cases Document**

*Last Updated: 2025-10-18*
*Ready for comprehensive testing of Phase 1 Task 2*
