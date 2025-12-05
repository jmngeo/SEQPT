# API Standardization Testing Checklist

**Date**: 2025-11-01
**Change**: Standardized all API endpoints to use `/api/` prefix

## Summary of Changes

1. **Backend**: Added `/api` prefix to main_bp blueprint registration
2. **Backend**: Removed `/api` prefix from 41 route definitions (to avoid double /api/api/)
3. **Frontend**: Updated 18 API calls across 7 files to use `/api/` prefix
4. **Frontend**: Simplified Vite proxy config from 12 individual proxies to 1 unified proxy
5. **Fixed**: Dashboard.vue to use relative URL instead of direct port 5000 access

## Pre-Testing Checklist

- [x] Backend server running on http://127.0.0.1:5000
- [x] Frontend server running on http://localhost:3000
- [x] Database connection verified
- [x] Health endpoint working: http://localhost:5000/health

## Critical Path Testing

### 1. Authentication & Login Flow
**Priority**: CRITICAL

#### Test Steps:
1. [ ] Navigate to http://localhost:3000
2. [ ] Click "Register as Admin"
3. [ ] Fill registration form:
   - Username: testadmin
   - Password: testpass123
   - Organization Name: Test Org
   - Organization Size: 11-50
4. [ ] Submit registration
5. [ ] Verify redirect to login page
6. [ ] Login with created credentials
7. [ ] Verify redirect to dashboard

#### Expected Endpoints Hit:
- `POST /api/mvp/auth/register-admin`
- `POST /api/mvp/auth/login`
- `GET /api/organization/dashboard?code=<ORG_CODE>`

#### Success Criteria:
- [ ] No console errors
- [ ] Authentication token stored in localStorage as `se_qpt_token`
- [ ] User redirected to dashboard after login
- [ ] Organization data loaded successfully

---

### 2. Dashboard Loading
**Priority**: CRITICAL

#### Test Steps:
1. [ ] After login, observe dashboard loading
2. [ ] Check browser console for errors
3. [ ] Verify competency stats card displays (may be empty for new user)
4. [ ] Verify phase cards display correctly

#### Expected Endpoints Hit:
- `GET /api/organization/dashboard?code=<ORG_CODE>`
- `GET /api/latest_competency_overview` (if assessment completed)

#### Success Criteria:
- [ ] No 404 errors in console
- [ ] No CORS errors in console
- [ ] Dashboard renders without JavaScript errors
- [ ] Phase progression logic works correctly

---

### 3. Phase 1 Task 1: Organization Context
**Priority**: HIGH

#### Test Steps:
1. [ ] Click "Start Phase 1" or navigate to Phases > Phase 1
2. [ ] Task 1 should load (Organization Context)
3. [ ] Select maturity levels for all categories
4. [ ] Click "Save and Continue"

#### Expected Endpoints Hit:
- `POST /api/organization/setup` (saves maturity assessment)
- `GET /api/organization/dashboard?code=<ORG_CODE>` (updates phase status)

#### Success Criteria:
- [ ] Form submits successfully
- [ ] No console errors
- [ ] Advances to Task 2
- [ ] Data persists if you refresh the page

---

### 4. Phase 1 Task 2: Role-Process Matrix
**Priority**: HIGH

#### Test Steps:
1. [ ] Add at least 2 custom roles (e.g., "Software Engineer", "System Architect")
2. [ ] Click "Continue" to Role-Process Matrix
3. [ ] Assign RACI values for at least 5 processes per role
4. [ ] Click "Save and Continue"

#### Expected Endpoints Hit:
- `GET /api/roles_and_processes` (loads processes)
- `PUT /api/role_process_matrix/bulk` (saves matrix for each role)

#### Success Criteria:
- [ ] Processes load successfully
- [ ] Matrix saves without errors
- [ ] Advances to Task 3
- [ ] Matrix data persists on page refresh

---

### 5. Phase 1 Task 3: Strategy Selection
**Priority**: MEDIUM

#### Test Steps:
1. [ ] Select a training strategy (Role-based or Task-based)
2. [ ] Click "Complete Phase 1"

#### Expected Endpoints Hit:
- `PUT /api/organization/phase1-complete`

#### Success Criteria:
- [ ] Phase 1 marked as complete
- [ ] Phase 2 becomes accessible
- [ ] Redirect to dashboard or Phase 2

---

### 6. Phase 2: Role Selection
**Priority**: HIGH

#### Test Steps:
1. [ ] Navigate to Phase 2
2. [ ] Select one of the roles created in Phase 1
3. [ ] Click "Continue"

#### Expected Endpoints Hit:
- `GET /api/roles` (if legacy flow)
- `GET /api/organization_roles/<org_id>` (loads organization roles)

#### Success Criteria:
- [ ] Roles load successfully
- [ ] Selected role persists
- [ ] Advances to necessary competencies view

---

### 7. Phase 2: Necessary Competencies
**Priority**: HIGH

#### Test Steps:
1. [ ] View the list of necessary competencies for selected role
2. [ ] Verify competencies display with required levels
3. [ ] Click "Start Assessment"

#### Expected Endpoints Hit:
- `POST /api/get_required_competencies_for_roles`

#### Success Criteria:
- [ ] Competencies load successfully
- [ ] Required levels display correctly
- [ ] No console errors

---

### 8. Phase 2: Competency Assessment
**Priority**: CRITICAL

#### Test Steps:
1. [ ] Answer all 15 competency questions
2. [ ] Use the slider to rate each competency (0-6)
3. [ ] Click "Submit Survey" on the last question
4. [ ] Confirm submission in dialog

#### Expected Endpoints Hit:
- `POST /api/phase2/submit-assessment`
- `GET /api/assessments/<id>/results` (loads results)

#### Success Criteria:
- [ ] All questions display correctly
- [ ] Submission succeeds without errors
- [ ] Redirect to results page with persistent URL
- [ ] Results display competency scores and gaps

---

### 9. Phase 2: Results Display
**Priority**: HIGH

#### Test Steps:
1. [ ] Verify competency results table displays
2. [ ] Check for proficiency badges (Proficient/Needs Development)
3. [ ] Verify LLM feedback displays for each competency
4. [ ] Click "Retake Assessment" button
5. [ ] Verify redirects to fresh assessment

#### Expected Endpoints Hit:
- `GET /api/assessments/<id>/results`
- `GET /api/latest_competency_overview` (for dashboard)

#### Success Criteria:
- [ ] Results table renders correctly
- [ ] Gaps calculated accurately
- [ ] LLM feedback displays (or shows generation in progress)
- [ ] Retake button works

---

### 10. Admin Panel: Process-Competency Matrix
**Priority**: MEDIUM

#### Test Steps:
1. [ ] Navigate to Admin Panel > Process-Competency Matrix
2. [ ] Wait for competencies and processes to load
3. [ ] Edit at least 3 cells (change importance levels)
4. [ ] Click "Save Changes"

#### Expected Endpoints Hit:
- `GET /api/competencies`
- `GET /api/roles_and_processes`
- `GET /api/process_competency_matrix/<competency_id>` (for each competency)
- `PUT /api/process_competency_matrix/bulk`

#### Success Criteria:
- [ ] Matrix loads without errors
- [ ] Cell edits work smoothly
- [ ] Changes save successfully
- [ ] Success message displays

---

### 11. Admin Panel: Role-Process Matrix
**Priority**: MEDIUM

#### Test Steps:
1. [ ] Navigate to Admin Panel > Role-Process Matrix
2. [ ] Wait for roles and processes to load
3. [ ] Edit RACI values for at least 3 cells
4. [ ] Click "Save Changes"

#### Expected Endpoints Hit:
- `GET /api/roles_and_processes`
- `GET /api/organization_roles/<org_id>`
- `PUT /api/role_process_matrix/bulk`

#### Success Criteria:
- [ ] Matrix loads successfully
- [ ] RACI dropdowns work correctly
- [ ] Changes save without errors
- [ ] Success message displays

---

### 12. Task-Based Workflow (Alternative to Role-Based)
**Priority**: HIGH

#### Test Steps:
1. [ ] Register new user/organization
2. [ ] Complete Phase 1 Task 1 & 2
3. [ ] Select "Task-Based" strategy in Task 3
4. [ ] In Phase 2, enter detailed task descriptions:
   - Responsible for: "Developing embedded software modules, writing unit tests"
   - Supporting: "Code reviews, mentoring junior developers"
   - Designing: "Software architecture for control systems"
5. [ ] Submit task analysis
6. [ ] Wait for LLM to identify processes
7. [ ] Continue to competency assessment

#### Expected Endpoints Hit:
- `POST /api/derik/public/identify-processes` (LLM process identification)
- `POST /api/get_required_competencies_for_roles` (with survey_type='unknown_roles')
- `POST /api/phase2/submit-assessment`

#### Success Criteria:
- [ ] Task analysis completes successfully
- [ ] LLM identifies relevant processes
- [ ] Competencies calculated based on process involvement
- [ ] Assessment works end-to-end

---

## Known Issues & Workarounds

### Issue 1: Empty Competency Scores
**Symptom**: All required competency scores show as 0 or 6
**Cause**: Minimal task input leads to "Not performing" for all processes
**Workaround**: Enter detailed, specific tasks in all three categories (Responsible for, Supporting, Designing)

### Issue 2: Database Trigger Overwriting Username
**Status**: FIXED
**Solution**: Database trigger updated to only set username when NULL

### Issue 3: Flask Hot-Reload Not Working
**Status**: KNOWN LIMITATION
**Workaround**: Always manually restart Flask server after code changes

---

## Regression Testing

After completing the above tests, verify these previously working features still work:

- [ ] User logout and re-login
- [ ] Navigation between phases
- [ ] Phase locking (can't access Phase 2 without completing Phase 1)
- [ ] Browser refresh maintains state
- [ ] Multiple users in same organization can complete assessments independently

---

## API Endpoint Verification

Use these curl commands to verify endpoints directly:

```bash
# Health check (not in blueprint)
curl http://localhost:5000/health

# Organization dashboard (with blueprint prefix)
curl "http://localhost:5000/api/organization/dashboard?code=<ORG_CODE>"

# Roles and processes (with blueprint prefix)
curl http://localhost:5000/api/roles_and_processes

# Competencies (with blueprint prefix, requires auth)
curl http://localhost:5000/api/competencies -H "Authorization: Bearer <TOKEN>"
```

---

## Performance Checks

- [ ] Page load times acceptable (< 2 seconds)
- [ ] No memory leaks in browser console
- [ ] Backend responds within 500ms for non-LLM endpoints
- [ ] LLM endpoints complete within 30 seconds

---

## Browser Console Checklist

Open browser DevTools > Console and verify:

- [ ] No 404 errors
- [ ] No CORS errors
- [ ] No "Failed to fetch" errors
- [ ] No "Missing Authorization Header" errors (except for public endpoints)
- [ ] No JavaScript exceptions

---

## Rollback Plan

If critical issues are found:

1. Revert backend routes:
   ```bash
   cd src/backend/app
   cp routes.py.backup routes.py
   ```

2. Revert backend blueprint registration:
   ```python
   # In src/backend/app/__init__.py line 74
   app.register_blueprint(main_bp)  # Remove url_prefix='/api'
   ```

3. Revert frontend API calls:
   ```bash
   git checkout src/frontend/src/api/
   git checkout src/frontend/src/components/
   git checkout src/frontend/src/views/
   ```

4. Restart servers

---

## Sign-Off

- [ ] All critical tests passed
- [ ] All high priority tests passed
- [ ] No console errors during happy path
- [ ] Performance acceptable
- [ ] Ready for production

**Tested by**: _________________
**Date**: _________________
**Notes**: _________________
