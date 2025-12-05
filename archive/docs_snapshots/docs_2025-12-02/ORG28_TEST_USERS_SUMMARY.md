# Organization 28 - Test Users Summary

**Date Created**: 2025-11-05
**Purpose**: Multiple employees with completed Phase 2 competency assessments for testing Phase 2 Task 3 learning objectives generation
**Organization**: 28 (Lowmaturity ORG)

---

## Overview

Successfully created **8 new test users** with completed competency assessments, bringing the total to **9 users** (including the original "lowmaturity" user).

### Statistics
- **Total Users**: 9
- **Completed Assessments**: 9 (100%)
- **Competency Results**: 144 (9 users × 16 competencies)
- **Assessment Type**: phase2_employee (task-based, low maturity pathway)
- **Survey Type**: unknown_roles (task-based assessment)

---

## Organization 28 Roles

The organization has 3 roles defined:

| Role ID | Role Name             | Description                |
|---------|-----------------------|----------------------------|
| 318     | Systems Engineer      | Core systems engineering   |
| 319     | Requirements Engineer | Requirements specialist    |
| 320     | Project Manager       | Project leadership         |

---

## Test User Profiles

### 1. Alice Excellence (emp_high_performer)
- **User ID**: 47
- **Email**: high.performer@org28.test
- **Role**: Systems Engineer (318)
- **Score Pattern**: **4-5** (High performer)
- **Profile**: Strong skills across all competencies
- **Use Case**: Testing with top-tier employee, minimal gaps

### 2. Bob Average (emp_mid_level)
- **User ID**: 48
- **Email**: mid.level@org28.test
- **Roles**: Systems Engineer (318) + Requirements Engineer (319)
- **Score Pattern**: **3-4** (Mid-range)
- **Profile**: Solid competencies, moderate gaps
- **Use Case**: Testing multi-role assignment with moderate performance

### 3. Charlie Junior (emp_entry_level)
- **User ID**: 49
- **Email**: entry.level@org28.test
- **Role**: Requirements Engineer (319)
- **Score Pattern**: **2-3** (Entry level)
- **Profile**: Entry-level employee needing significant development
- **Use Case**: Testing with new hire, large competency gaps

### 4. Diana Variable (emp_mixed)
- **User ID**: 50
- **Email**: mixed.skills@org28.test
- **Role**: Systems Engineer (318)
- **Score Pattern**: **1-5** (Highly varied)
- **Profile**: Mixed competency levels, some strong, some weak
- **Use Case**: Testing irregular performance patterns

### 5. Edward Beginner (emp_low_performer)
- **User ID**: 51
- **Email**: low.performer@org28.test
- **Role**: Requirements Engineer (319)
- **Score Pattern**: **1-2** (Low/Beginner)
- **Profile**: New employee needing comprehensive training
- **Use Case**: Testing with maximum training needs

### 6. Frank Technical (emp_tech_specialist)
- **User ID**: 52
- **Email**: tech.specialist@org28.test
- **Role**: Systems Engineer (318)
- **Score Pattern**: **Technical 4-5, Management 1-2, Core 3-4**
- **Profile**: Strong technical skills, weak management competencies
- **Use Case**: Testing specialized skill profiles (technical specialist)

**Sample Scores**:
- Technical competencies (Communication, Requirements, Architecting, etc.): 4-5
- Management competencies (Leadership, Project Mgmt, Decision, etc.): 1-2
- Core competencies: 3-4

### 7. Grace Leadership (emp_manager)
- **User ID**: 53
- **Email**: manager@org28.test
- **Role**: Project Manager (320)
- **Score Pattern**: **Management 4-5, Technical 2-3, Core 3-4**
- **Profile**: Strong management skills, moderate technical competencies
- **Use Case**: Testing specialized skill profiles (management specialist)

### 8. Henry Steady (emp_balanced)
- **User ID**: 54
- **Email**: balanced@org28.test
- **Roles**: Systems Engineer (318) + Project Manager (320)
- **Score Pattern**: **3** (All scores = 3)
- **Profile**: Balanced employee with consistent moderate skills
- **Use Case**: Testing consistent/flat performance profile

### 9. lowmaturity (existing user)
- **User ID**: 39
- **Username**: lowmaturity
- **Competency Results**: 148 (from multiple assessments over time)
- **Profile**: Original test user with extensive assessment history

---

## Competency Score Verification

Sample scores for selected users confirm pattern accuracy:

### emp_high_performer (High Performer)
- All scores: 4-5
- Example: Systems Thinking (5), Leadership (4), Communication (5)

### emp_low_performer (Beginner)
- All scores: 1-2
- Example: Systems Thinking (2), Leadership (1), Communication (1)

### emp_tech_specialist (Technical Specialist)
- Technical: Integration/Verification (5), Agile (5), Architecting (4)
- Management: Configuration Mgmt (1), Leadership (2), Project Mgmt (2)
- Core: Systems Thinking (4), Systems Modeling (4)

---

## Database Schema

### Tables Populated

1. **users**
   - 9 users in org 28
   - All with first_name, last_name, email, username

2. **user_assessment**
   - 9+ completed assessments (some users have multiple historical assessments)
   - All marked as phase2_employee / unknown_roles
   - All have completed_at timestamp

3. **user_se_competency_survey_results**
   - 144+ competency results for org 28
   - Each completed assessment has 16 competencies (IDs: 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18)
   - Scores range from 1-5 based on user profile

4. **user_role_cluster**
   - Role mappings for all users
   - Links users to organization_roles (318, 319, 320)

---

## Testing Scenarios Covered

### 1. Performance Levels
- [x] High performer (4-5)
- [x] Mid-level (3-4)
- [x] Entry level (2-3)
- [x] Low performer (1-2)
- [x] Mixed performance (1-5)
- [x] Consistent average (all 3s)

### 2. Role Configurations
- [x] Single role assignment
- [x] Multi-role assignment (2 roles)
- [x] Different roles (Systems Engineer, Requirements Engineer, Project Manager)

### 3. Competency Patterns
- [x] Balanced skills (all competencies similar)
- [x] Technical specialist (strong technical, weak management)
- [x] Manager profile (strong management, moderate technical)
- [x] Irregular patterns (mixed strong/weak areas)

### 4. Training Needs
- [x] Minimal training needs (high performers)
- [x] Moderate training needs (mid-level)
- [x] Extensive training needs (beginners)
- [x] Targeted training needs (specialists)

---

## Phase 2 Task 3 Testing

### Expected Behavior

With 9 completed assessments:

1. **Assessment Monitor** should show:
   - Total employees: 9
   - Completed assessments: 9
   - Completion rate: 100%

2. **Learning Objectives Generation** should:
   - Calculate competency requirements based on roles
   - Compare current levels vs. required levels
   - Identify competency gaps for each user
   - Generate personalized learning recommendations
   - Apply selected learning strategies (7 archetypes configured)

3. **Results Display** should show:
   - Learning objectives for all 16 competencies
   - Varying target levels based on roles
   - Different gap sizes based on individual performance
   - Strategy-specific recommendations

---

## Verification Queries

```sql
-- Count users
SELECT COUNT(*) FROM users WHERE organization_id = 28;
-- Expected: 9

-- Count completed assessments
SELECT COUNT(*) FROM user_assessment
WHERE organization_id = 28 AND completed_at IS NOT NULL;
-- Expected: 9+

-- Count competency results
SELECT COUNT(*) FROM user_se_competency_survey_results
WHERE organization_id = 28;
-- Expected: 144+

-- User details
SELECT id, username, first_name, last_name
FROM users
WHERE organization_id = 28
ORDER BY id;

-- Assessment summary by user
SELECT
    ua.user_id,
    u.username,
    COUNT(ucsr.id) as competency_count,
    ua.completed_at
FROM user_assessment ua
JOIN users u ON ua.user_id = u.id
LEFT JOIN user_se_competency_survey_results ucsr ON ua.id = ucsr.assessment_id
WHERE ua.organization_id = 28
GROUP BY ua.user_id, u.username, ua.completed_at
ORDER BY ua.user_id;
```

---

## Next Steps

### 1. Frontend Testing
- Navigate to: `http://localhost:3000/app/phases/2/admin/learning-objectives?orgId=28`
- Verify Assessment Monitor displays: **9/9 users completed**
- Generate learning objectives
- Verify results display for all users

### 2. Backend Validation
- Check Phase 2 algorithm processes all 9 users
- Verify competency gap calculations
- Confirm learning strategy application

### 3. Edge Cases to Test
- Multi-role users (Bob, Henry) - should use MAX requirement
- Specialized profiles (Frank, Grace) - targeted recommendations
- Low performers (Edward) - comprehensive training plans
- High performers (Alice) - minimal or no training needs

---

## Script Location

**Script**: `create_test_users_org28.py`
**Location**: Project root directory

### Re-running the Script
The script is idempotent - it will skip users that already exist:
```bash
cd /c/Users/jomon/Documents/MyDocuments/Development/Thesis/SE-QPT-Master-Thesis
PYTHONPATH=src/backend python create_test_users_org28.py
```

### Cleaning Up Test Users
To remove all test users (keep only original):
```sql
DELETE FROM user_se_competency_survey_results
WHERE user_id IN (47, 48, 49, 50, 51, 52, 53, 54);

DELETE FROM user_role_cluster
WHERE user_id IN (47, 48, 49, 50, 51, 52, 53, 54);

DELETE FROM user_assessment
WHERE user_id IN (47, 48, 49, 50, 51, 52, 53, 54);

DELETE FROM users
WHERE id IN (47, 48, 49, 50, 51, 52, 53, 54);
```

---

## Success Criteria

- [x] 8 new users created
- [x] All users have completed assessments
- [x] All assessments have 16 competency results
- [x] Score patterns match intended profiles
- [x] Multi-role assignments work correctly
- [x] Varied competency patterns (technical, management, balanced)
- [x] Database integrity maintained (all foreign keys valid)

---

**Status**: COMPLETE
**Ready for**: Phase 2 Task 3 frontend testing with realistic multi-user data
