# SE-QPT Integration Testing Guide

**Date:** 2025-10-02
**Status:** Ready for End-to-End Testing

---

## 🚀 Current System Status

### Backend Services
- ✅ **Derik's Flask** - Running on `http://localhost:5000` (Docker)
- ⏳ **SE-QPT Backend** - Need to start on different port (e.g., 5001)
- ✅ **PostgreSQL** - Running on `localhost:5432` (Docker)

### Frontend Services
- ✅ **Vue/Vite Dev Server** - Running on `http://localhost:3000`

### Database Status
```
✓ organization - Extended with Phase 1 fields
✓ user_se_competency_survey_results - Extended with gap analysis
✓ learning_plans - Created
✓ questionnaire_responses - Created
✓ 16 Competencies loaded
✓ 16 Role clusters loaded
```

---

## 📋 Testing Checklist

### Phase 0: Environment Setup ✓

- [x] Database migrations applied
- [x] Backend models unified
- [x] API routes updated
- [x] Frontend running on port 3000
- [ ] SE-QPT backend running on port 5001
- [ ] Backend API accessible from frontend

### Phase 1: Organization & Registration Flow

#### Test 1.1: Admin Registration
**Endpoint:** `POST /mvp/auth/register-admin`

**Test Data:**
```json
{
  "username": "admin_test",
  "password": "Test123!",
  "first_name": "Test",
  "last_name": "Admin",
  "organization_name": "Test Organization Inc",
  "organization_size": "medium"
}
```

**Expected Result:**
```json
{
  "access_token": "<JWT>",
  "user": {
    "id": "<uuid>",
    "username": "admin_test",
    "role": "admin",
    "organization_id": <integer>
  },
  "organization": {
    "id": <integer>,
    "organization_name": "Test Organization Inc",
    "organization_code": "<16-char-uppercase>",
    "size": "medium"
  },
  "organization_code": "<16-char-uppercase>"
}
```

**Validation:**
- [ ] Organization created in database with `organization_public_key`
- [ ] Admin user created with correct role
- [ ] JWT token received
- [ ] Organization code is 16 uppercase characters

#### Test 1.2: Organization Code Verification
**Endpoint:** `GET /api/organization/verify-code/<code>`

**Test:**
```bash
curl http://localhost:5001/api/organization/verify-code/<ORG_CODE>
```

**Expected:**
```json
{
  "valid": true,
  "organization_name": "Test Organization Inc"
}
```

**Validation:**
- [ ] Code verification works with `organization_public_key`
- [ ] Returns correct organization name
- [ ] Returns `valid: false` for invalid codes

#### Test 1.3: Employee Registration
**Endpoint:** `POST /mvp/auth/register-employee`

**Test Data:**
```json
{
  "username": "employee_test",
  "password": "Test123!",
  "first_name": "Test",
  "last_name": "Employee",
  "organization_code": "<FROM_TEST_1.1>"
}
```

**Expected:**
- [ ] Employee user created
- [ ] Linked to correct organization
- [ ] `joined_via_code` field populated
- [ ] JWT token received

---

### Phase 2: Maturity Assessment Flow (Phase 1)

#### Test 2.1: Maturity Assessment Submission
**Endpoint:** `POST /api/maturity-assessment`

**Test Data:**
```json
{
  "responses": [
    {"question_id": 1, "score": 3},
    {"question_id": 2, "score": 4},
    // ... 33 questions total
  ]
}
```

**Expected:**
- [ ] Maturity scores calculated (scope_score, process_score)
- [ ] Overall maturity level determined
- [ ] Stored in `maturity_assessments` table
- [ ] Organization updated with `maturity_score`

#### Test 2.2: Archetype Selection
**Endpoint:** `PUT /api/organization/archetype`

**Test Data:**
```json
{
  "archetype": "Common Basic Understanding",
  "maturity_result": {
    "scope_score": 2.5,
    "process_score": 3.0,
    "overall_maturity": "Developing"
  }
}
```

**Expected:**
- [ ] Organization updated with `selected_archetype`
- [ ] `phase1_completed` set to `true`
- [ ] Archetype-competency matrix loaded for user

---

### Phase 3: Competency Assessment Flow (Phase 2)

#### Test 3.1: Competency Assessment Submission
**Endpoint:** `POST /api/competency-assessment`

**Test Data:**
```json
{
  "assessments": [
    {"competency_id": 1, "current_level": 2},
    {"competency_id": 2, "current_level": 1},
    // ... for all 16 competencies
  ]
}
```

**Expected:**
- [ ] Assessments stored in `user_se_competency_survey_results`
- [ ] Gap analysis performed automatically
- [ ] `target_level` from archetype matrix
- [ ] `gap_size` calculated (target - current)
- [ ] `archetype_source` populated

**Database Validation:**
```sql
SELECT
  competency_id,
  score as current_level,
  target_level,
  gap_size,
  archetype_source
FROM user_se_competency_survey_results
WHERE user_id = <test_user_id>;
```

#### Test 3.2: Gap Analysis Results
**Endpoint:** `GET /api/assessments/gaps`

**Expected Response:**
```json
{
  "gaps": [
    {
      "competency_id": 1,
      "competency_name": "Systems Thinking",
      "current_level": 2,
      "target_level": 4,
      "gap_size": 2,
      "archetype": "Common Basic Understanding"
    }
  ]
}
```

---

### Phase 4: Learning Objectives Generation

#### Test 4.1: Standard Learning Objectives Selection
**Process:**
1. For each competency with gap > 0
2. Get target level from gap analysis
3. Convert archetype scale to excel scale (if needed)
4. Look up in `standard_learning_objectives.json`

**Example:**
```
Competency ID: 1 (Systems Thinking)
Target Level: 4 (from archetype "Common Basic Understanding")
Excel Level: 4 (Apply)
Standard Objective: "The participant is able to analyze his existing
                     system and derive continuous improvements from it."
```

**Validation:**
- [ ] Correct standard objectives retrieved
- [ ] Level mapping works correctly (1,2,4,6)
- [ ] Objectives stored in `learning_plans` table

#### Test 4.2: RAG-LLM Enhanced Objectives (Optional)
**If using company context:**

**Endpoint:** `POST /api/learning-objectives/generate`

**Test Data:**
```json
{
  "competency_id": 1,
  "target_level": 4,
  "current_level": 2,
  "company_context": {
    "industry": "Aerospace",
    "project_type": "Satellite Systems"
  }
}
```

**Expected:**
- [ ] Standard objective enhanced with context
- [ ] SMART format maintained
- [ ] Stored in `learning_plans.objectives` (JSON)

---

### Phase 5: Full Integration Testing

#### Test 5.1: End-to-End Workflow
**Complete User Journey:**

1. **Admin Registration** → Organization created ✓
2. **Get Organization Code** → Share with employees ✓
3. **Employee Registration** → Join organization ✓
4. **Maturity Assessment** → Complete 33 questions ✓
5. **Archetype Selection** → Automatic or manual ✓
6. **Competency Assessment** → 16 competencies ✓
7. **Gap Analysis** → Automatic calculation ✓
8. **Learning Objectives** → Standard + RAG-LLM ✓
9. **Learning Plan** → Generated and stored ✓

#### Test 5.2: Data Integrity Validation
```sql
-- Check complete user journey data
SELECT
  u.username,
  o.organization_name,
  o.selected_archetype,
  o.maturity_score,
  COUNT(DISTINCT s.competency_id) as assessed_competencies,
  COUNT(DISTINCT CASE WHEN s.gap_size > 0 THEN s.competency_id END) as competencies_with_gaps,
  lp.id as learning_plan_id,
  json_array_length(lp.objectives::json) as objectives_count
FROM app_user u
JOIN organization o ON u.organization_id = o.id
LEFT JOIN user_se_competency_survey_results s ON s.user_id = u.id
LEFT JOIN learning_plans lp ON lp.user_id = u.id
WHERE u.username = 'employee_test'
GROUP BY u.username, o.organization_name, o.selected_archetype,
         o.maturity_score, lp.id, lp.objectives;
```

---

## 🔧 Testing Tools

### Manual Testing via Frontend
1. Open browser: `http://localhost:3000`
2. Navigate through UI workflow
3. Check browser console for errors
4. Verify data in PostgreSQL

### API Testing with Postman/curl
```bash
# Admin Registration
curl -X POST http://localhost:5001/mvp/auth/register-admin \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin1",
    "password": "Test123!",
    "first_name": "John",
    "last_name": "Admin",
    "organization_name": "Acme Corp",
    "organization_size": "large"
  }'

# Verify Org Code
curl http://localhost:5001/api/organization/verify-code/<CODE>

# Employee Registration
curl -X POST http://localhost:5001/mvp/auth/register-employee \
  -H "Content-Type: application/json" \
  -d '{
    "username": "employee1",
    "password": "Test123!",
    "first_name": "Jane",
    "last_name": "Doe",
    "organization_code": "<CODE>"
  }'
```

### Database Verification
```bash
# Connect to PostgreSQL
docker exec -it competency_assessor-postgres-1 psql -U ma0349 -d competency_assessment

# Check organization
SELECT * FROM organization ORDER BY created_at DESC LIMIT 1;

# Check users
SELECT id, username, role, organization_id FROM app_user;

# Check competency assessments
SELECT * FROM user_se_competency_survey_results
WHERE user_id = <user_id>
ORDER BY competency_id;

# Check learning plans
SELECT * FROM learning_plans WHERE user_id = <user_id>;
```

---

## 🐛 Known Issues to Watch For

1. **Organization Code Field Name**
   - Frontend may expect `organization_code`
   - Backend returns `organization_public_key`
   - Check: `organization.to_dict()` has alias

2. **Scale Mismatch**
   - Archetype matrix uses 0-5 scale
   - Learning objectives use 1,2,4,6 scale
   - Need conversion function

3. **RoleMapping Placeholder**
   - Currently minimal implementation
   - May need to implement before role-based features

---

## ✅ Success Criteria

### Minimum Viable Product (MVP)
- [ ] Admin can register and create organization
- [ ] Employees can join using organization code
- [ ] Maturity assessment calculates scores correctly
- [ ] Archetype selection works
- [ ] Competency assessment stores results
- [ ] Gap analysis calculates correctly
- [ ] Learning objectives are generated

### Full Integration
- [ ] All data persists correctly in unified database
- [ ] No duplicate data in Derik vs SE-QPT tables
- [ ] Frontend → Backend → Database flow works
- [ ] Standard learning objectives match archetype levels
- [ ] RAG-LLM enhancement works (optional)

---

## 📝 Next Steps After Testing

1. **Fix any identified bugs**
2. **Document API changes for frontend**
3. **Implement RoleMapping if needed**
4. **Add error handling and validation**
5. **Create automated test suite**
6. **Prepare for production deployment**

---

**Ready to test!** Start with Phase 1 (Organization & Registration) and work through each phase sequentially.
