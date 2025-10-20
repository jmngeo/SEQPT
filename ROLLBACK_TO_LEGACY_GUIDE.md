# Rollback to Legacy Implementation - Step-by-Step Guide

**Date:** 2025-10-20
**Purpose:** Restore working Derik legacy implementation
**Reason:** New Phase 2 implementation has critical bugs (see PHASE2_VALIDATION_REPORT.md)

---

## Prerequisites

**Before you start:**
- ✅ Backup branch created: `phase2-new-broken`
- ⚠️ All servers must be stopped (node.js and Flask processes)
- ⚠️ You will lose uncommitted changes (but they're saved in the backup branch)

---

## Step-by-Step Rollback Process

### Step 1: Stop All Running Servers

**Close all terminal windows running:**
- Frontend dev server (npm run dev)
- Backend Flask server (flask run)

**OR manually kill processes:**

```bash
# In PowerShell or Command Prompt
taskkill /F /IM python.exe
taskkill /F /IM node.exe
```

Wait 5 seconds for processes to fully terminate.

---

### Step 2: Delete node_modules Directory

**This is the critical step - locked binary files prevent git reset.**

```bash
cd src/frontend
rmdir /s node_modules
# Answer 'Y' when prompted
```

If this fails with "Directory not empty" or access denied:
1. Open File Explorer
2. Navigate to `src/frontend/`
3. Right-click `node_modules` folder → Delete
4. If you get access denied, close ALL editor/IDE windows
5. Try again

---

### Step 3: Perform Git Reset

```bash
# Go back to project root
cd C:\Users\jomon\Documents\MyDocuments\Development\Thesis\SE-QPT-Master-Thesis

# Reset to legacy commit
git reset --hard 0b6a326d
```

**Expected output:**
```
HEAD is now at 0b6a326d before phase 2 migration
```

---

### Step 4: Verify Rollback Success

```bash
git status
```

**Expected output:**
- Branch: master
- Clean working directory OR only untracked files

```bash
git log --oneline -5
```

**Expected output:**
```
0b6a326d (HEAD -> master) before phase 2 migration
... (older commits)
```

---

### Step 5: Reinstall Frontend Dependencies

```bash
cd src/frontend
npm install
```

**Expected:** Installation completes successfully

---

### Step 6: Verify Legacy Files Exist

**Check these files are present:**

```bash
# Legacy Phase 2 component (should exist)
ls src/frontend/src/components/assessment/DerikCompetencyBridge.vue

# New Phase 2 components (should NOT exist)
ls src/frontend/src/components/phase2/Phase2TaskFlowContainer.vue
```

**Expected:**
- DerikCompetencyBridge.vue exists ✅
- Phase2TaskFlowContainer.vue does NOT exist ✅

---

### Step 7: Start Servers and Test

**Terminal 1 - Backend:**
```bash
cd src/competency_assessor
set DATABASE_URL=postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment
set FLASK_APP=run.py
set FLASK_DEBUG=1
set FLASK_RUN_PORT=5003
flask run --port=5003
```

**Terminal 2 - Frontend:**
```bash
cd src/frontend
npm run dev
```

**Terminal 3 - Test:**
```bash
# Test backend health
curl http://localhost:5003/

# Test competency endpoint
curl http://localhost:5003/competencies
```

---

### Step 8: Browser Testing

**Open:** `http://localhost:3001/app/phases/2` (NOT `/app/phases/2/new`)

**Test all 3 assessment modes:**

1. **Role-Based Assessment**
   - Select 1-2 roles
   - Complete competency survey (16 questions)
   - Verify results page shows:
     - Radar chart ✅
     - LLM feedback ✅
     - PDF export button ✅

2. **Task-Based Assessment**
   - Describe job tasks in all 3 fields
   - Verify AI identifies processes
   - Complete survey (16 questions)
   - Verify results

3. **Full Competency Assessment**
   - Start assessment directly
   - Complete survey (16 questions)
   - Verify role suggestions appear
   - Verify results

---

## Verification Checklist

After rollback, verify:

- [ ] Git is at commit `0b6a326d`
- [ ] node_modules reinstalled successfully
- [ ] Backend starts without errors
- [ ] Frontend starts without errors
- [ ] Can access `/app/phases/2` route
- [ ] Role-based assessment works
- [ ] Task-based assessment works
- [ ] Full competency assessment works
- [ ] Radar chart displays correctly
- [ ] LLM feedback appears in results
- [ ] PDF export works
- [ ] All 16 competencies are assessed (NOT filtered)

---

## If Rollback Fails

**Problem:** Git reset still fails even after deleting node_modules

**Solution:** Manual file restoration

```bash
# 1. Create a fresh clone
cd C:\Users\jomon\Documents\MyDocuments\Development\Thesis
git clone <repository-url> SE-QPT-Legacy

# 2. Checkout legacy commit
cd SE-QPT-Legacy
git checkout 0b6a326d

# 3. Copy files from fresh clone to your working directory
# (manually or using robocopy)
```

---

## After Successful Rollback

### Document Legacy Code

**Priority:** Document Derik's implementation BEFORE making changes

1. **Map all API endpoints:**
   - `POST /get_required_competencies_for_roles`
   - `GET /get_competency_indicators_for_competency/<id>`
   - `POST /submit_survey`
   - `GET /get_user_competency_results`
   - `POST /new_survey_user`
   - `POST /findProcesses`

2. **Document component flow:**
   - DerikCompetencyBridge.vue workflow
   - SurveyResults.vue data format
   - Score mapping logic
   - LLM feedback generation

3. **Create test cases:**
   - Test data for each assessment mode
   - Expected results
   - Edge cases

### Plan Incremental Feature Additions

**Phase 1 (Week 1): Add Phase 1 Role Mode**
- Keep DerikCompetencyBridge.vue
- Add 4th mode: "phase1-identified-roles"
- Fetch roles from `/api/phase2/identified-roles/<org_id>`
- Still assess ALL 16 competencies (no filtering)
- Test thoroughly

**Phase 2 (Week 2): Add Competency Preview**
- Before survey, show which competencies will be assessed
- Display calculated necessary competencies
- Still assess ALL 16 (no filtering yet)

**Phase 3 (Week 3-4): Add Dynamic Filtering**
- Filter competencies: `role_competency_value > 0`
- Only fetch indicators for necessary ones
- Only ask N questions (not 16)
- Modify results page to handle N < 16 competencies

**Phase 4 (Week 5): Integration & Testing**
- Ensure all 4 modes work
- Verify LLM feedback works for all
- Test PDF export with filtered competencies
- User acceptance testing

---

## Backup Branch Reference

**Your new Phase 2 work is saved in:**
```bash
git branch phase2-new-broken
```

**To review it later:**
```bash
git checkout phase2-new-broken
```

**Files you can salvage later:**
- Backend filtering logic (if needed)
- Frontend competency preview component
- Step indicator UI

---

## Summary

**What rollback gives you:**
- ✅ 100% working Phase 2 assessment
- ✅ All 3 modes functional (role, task, full)
- ✅ Radar chart working
- ✅ LLM feedback working
- ✅ PDF export working
- ✅ Proven, tested codebase

**What you lose:**
- ❌ Phase 1 identified roles integration (can add back incrementally)
- ❌ Competency preview screen (can add back incrementally)
- ❌ Dynamic filtering (can add back incrementally)

**Net result:** Working system NOW + ability to add features incrementally and safely

---

**Status:** READY TO EXECUTE
**Estimated Time:** 15-20 minutes
**Risk Level:** LOW (backup created)
