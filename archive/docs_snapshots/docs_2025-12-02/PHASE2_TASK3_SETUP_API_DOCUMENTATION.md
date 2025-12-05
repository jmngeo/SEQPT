# Phase 2 Task 3 - Automatic Setup API Documentation
**Date**: November 6, 2025
**Status**: ✅ IMPLEMENTED

---

## Overview

Automatic Phase 2 Task 3 setup for organizations via API endpoint.

**Purpose**: Automatically create learning strategy references for new organizations, linking them to global strategy templates without data duplication.

---

## API Endpoint

### **POST** `/api/phase2/learning-objectives/<org_id>/setup`

Creates 7 learning_strategy instances for an organization, each referencing a global strategy_template.

**Authentication**: Required (JWT token)

**Request**:
```http
POST /api/phase2/learning-objectives/30/setup
Authorization: Bearer <jwt_token>
```

**Success Response** (200):
```json
{
  "success": true,
  "organization_id": 30,
  "organization_name": "New Company",
  "strategies_created": 7,
  "strategies": [
    {
      "name": "Common basic understanding",
      "requires_pmt": false
    },
    {
      "name": "SE for managers",
      "requires_pmt": false
    },
    {
      "name": "Orientation in pilot project",
      "requires_pmt": false
    },
    {
      "name": "Needs-based, project-oriented training",
      "requires_pmt": true
    },
    {
      "name": "Continuous support",
      "requires_pmt": true
    },
    {
      "name": "Train the trainer",
      "requires_pmt": false
    },
    {
      "name": "Certification",
      "requires_pmt": false
    }
  ]
}
```

**Error Responses**:

**400 - Already Setup**:
```json
{
  "success": false,
  "error": "Organization 30 already has 7 strategies",
  "existing_count": 7
}
```

**404 - Not Found**:
```json
{
  "success": false,
  "error": "Organization 30 not found"
}
```

**500 - Server Error**:
```json
{
  "success": false,
  "error": "An error occurred during setup",
  "details": "<error message>"
}
```

---

## Integration Methods

### **Method 1: Manual API Call (Admin)**

```javascript
// Frontend - Admin Dashboard
async function setupPhase2Task3(organizationId) {
  try {
    const response = await axios.post(
      `/api/phase2/learning-objectives/${organizationId}/setup`,
      {},
      {
        headers: {
          Authorization: `Bearer ${getToken()}`
        }
      }
    );

    if (response.data.success) {
      console.log(`Setup complete: ${response.data.strategies_created} strategies created`);
      return response.data;
    }
  } catch (error) {
    if (error.response.status === 400) {
      console.log('Organization already setup');
    } else {
      console.error('Setup failed:', error);
    }
  }
}

// Usage
await setupPhase2Task3(30);
```

### **Method 2: Automatic on Organization Creation**

```python
# Backend - Organization creation endpoint
@app.route('/api/organizations', methods=['POST'])
@jwt_required()
def create_organization():
    try:
        data = request.get_json()

        # Create organization
        new_org = Organization(
            name=data['name'],
            maturity_level=data.get('maturity_level', 1),
            # ... other fields
        )
        db.session.add(new_org)
        db.session.commit()

        # Automatically setup Phase 2 Task 3
        setup_result = setup_phase2_task3_strategies(
            new_org.id,
            db_session=db.session
        )

        if not setup_result['success']:
            # Log warning but don't fail org creation
            current_app.logger.warning(
                f"Phase 2 Task 3 setup failed for org {new_org.id}: "
                f"{setup_result['error']}"
            )

        return jsonify({
            'success': True,
            'organization': new_org.to_dict(),
            'phase2_setup': setup_result
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
```

### **Method 3: CLI Script**

```bash
# Direct command-line execution
cd src/backend/setup
python setup_phase2_task3_for_org.py 30

# Verify setup
python setup_phase2_task3_for_org.py 30 --verify
```

---

## What the Setup Does

### **Before Setup**:
```
Organization 30:
- No learning strategies
- Cannot select strategies in Phase 1
- Cannot complete Phase 2 assessments
```

### **After Setup**:
```
Organization 30:
- 7 learning_strategy records (IDs 34-40)
- Each strategy_template_id points to global templates
- No competency data duplicated (uses template references)
- Ready for:
  ✅ Phase 1: Strategy selection
  ✅ Phase 2: Competency assessments
  ✅ Phase 2 Task 3: Learning objectives generation
```

### **Database Changes**:
```sql
-- Inserts 7 records into learning_strategy table
INSERT INTO learning_strategy (
  organization_id,
  strategy_template_id,
  strategy_name,
  strategy_description,
  selected,
  priority
) VALUES
  (30, 1, 'Common basic understanding', '...', false, 1),
  (30, 2, 'SE for managers', '...', false, 2),
  (30, 3, 'Orientation in pilot project', '...', false, 3),
  (30, 4, 'Needs-based, project-oriented training', '...', false, 4),
  (30, 5, 'Continuous support', '...', false, 5),
  (30, 6, 'Train the trainer', '...', false, 6),
  (30, 7, 'Certification', '...', false, 7);

-- Total: 7 rows added (just references, no competency data duplicated)
```

---

## Architecture Benefits

### **Data Efficiency**:
```
WITHOUT Global Templates (Old Way):
- 10 orgs × 7 strategies × 16 competencies = 1,120 rows
- 100 orgs × 7 strategies × 16 competencies = 11,200 rows

WITH Global Templates (New Way):
- 7 templates × 16 competencies = 112 rows (one time)
- 100 orgs × 7 references = 700 rows
- Total: 812 rows (93% reduction!)
```

### **Consistency Guarantee**:
- All organizations use identical strategy definitions
- Update template → all orgs updated automatically
- No risk of inconsistency across organizations

### **Single Source of Truth**:
- Strategy names: Stored once in `strategy_template`
- Competency targets: Stored once in `strategy_template_competency`
- Organization instances: Just selection flags and priorities

---

## Testing the API

### **cURL Example**:
```bash
# Get JWT token first
TOKEN=$(curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' \
  | jq -r '.access_token')

# Setup Phase 2 Task 3 for organization 30
curl -X POST http://localhost:5000/api/phase2/learning-objectives/30/setup \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  | jq .
```

### **Expected Output**:
```json
{
  "success": true,
  "organization_id": 30,
  "organization_name": "Test Organization",
  "strategies_created": 7,
  "strategies": [
    {"name": "Common basic understanding", "requires_pmt": false},
    {"name": "SE for managers", "requires_pmt": false},
    {"name": "Orientation in pilot project", "requires_pmt": false},
    {"name": "Needs-based, project-oriented training", "requires_pmt": true},
    {"name": "Continuous support", "requires_pmt": true},
    {"name": "Train the trainer", "requires_pmt": false},
    {"name": "Certification", "requires_pmt": false}
  ]
}
```

---

## Verification

### **Check Setup Was Successful**:
```sql
-- Verify strategies were created
SELECT
  ls.id,
  st.strategy_name,
  ls.selected,
  ls.priority
FROM learning_strategy ls
JOIN strategy_template st ON ls.strategy_template_id = st.id
WHERE ls.organization_id = 30
ORDER BY ls.priority;

-- Expected: 7 rows
```

### **Check Competency Access**:
```sql
-- Verify organization can access competency targets through templates
SELECT
  st.strategy_name,
  COUNT(stc.id) as competency_count
FROM learning_strategy ls
JOIN strategy_template st ON ls.strategy_template_id = st.id
LEFT JOIN strategy_template_competency stc ON st.id = stc.strategy_template_id
WHERE ls.organization_id = 30
GROUP BY st.strategy_name;

-- Expected: 7 rows, each with 16 competencies
```

---

## Files Modified

**Backend**:
- `src/backend/app/routes.py` (lines 43-50: import, lines 4520-4589: endpoint)
- `src/backend/setup/setup_phase2_task3_for_org.py` (setup function)

**Documentation**:
- `PHASE2_TASK3_SETUP_API_DOCUMENTATION.md` (this file)
- `PHASE2_TASK3_STANDARDIZATION_PLAN.md` (architectural design)

---

## Important Notes

### **1. Competency Name Standardization**

✅ **FIXED**: Database now uses "Systems **Modelling** and Analysis" (British spelling) to match template JSON.

**Consistency Check**:
- Database (competency table): "Systems Modelling and Analysis" ✅
- Template JSON: "Systems Modelling and Analysis" ✅
- All strategy templates now have 16 competencies (including ID 6) ✅

### **2. Idempotency**

The setup endpoint is **idempotent**:
- First call: Creates 7 strategies, returns 200
- Second call: Returns 400 "already has strategies"
- Safe to call multiple times

### **3. Transaction Safety**

- Uses SQLAlchemy session transactions
- Rolls back on error
- No partial setups (all 7 or none)

### **4. Authentication**

- Requires JWT authentication (`@jwt_required()`)
- Add admin-only check if needed:
  ```python
  @jwt_required()
  def api_setup_phase2_task3(organization_id):
      current_user_id = get_jwt_identity()
      user = User.query.get(current_user_id)
      if not user.is_admin:
          return jsonify({'error': 'Admin access required'}), 403
      # ... rest of endpoint
  ```

---

## Future Enhancements

### **1. Batch Setup**

Create endpoint to setup multiple organizations:
```python
@main_bp.route('/phase2/learning-objectives/batch-setup', methods=['POST'])
@jwt_required()
def api_batch_setup_phase2_task3():
    """Setup Phase 2 Task 3 for multiple organizations"""
    org_ids = request.json.get('organization_ids', [])
    results = []
    for org_id in org_ids:
        result = setup_phase2_task3_strategies(org_id, db_session=db.session)
        results.append(result)
    return jsonify({'results': results}), 200
```

### **2. Reset Endpoint**

Allow resetting strategies (delete and recreate):
```python
@main_bp.route('/phase2/learning-objectives/<int:org_id>/reset', methods=['DELETE'])
@jwt_required()
def api_reset_phase2_task3(organization_id):
    """Delete and recreate Phase 2 Task 3 strategies"""
    # Delete existing
    LearningStrategy.query.filter_by(organization_id=organization_id).delete()
    db.session.commit()
    # Recreate
    result = setup_phase2_task3_strategies(organization_id, db_session=db.session)
    return jsonify(result), 200
```

### **3. Status Check Endpoint**

Check if organization is setup:
```python
@main_bp.route('/phase2/learning-objectives/<int:org_id>/status', methods=['GET'])
def api_phase2_task3_status(organization_id):
    """Check Phase 2 Task 3 setup status"""
    count = LearningStrategy.query.filter_by(organization_id=organization_id).count()
    return jsonify({
        'organization_id': organization_id,
        'is_setup': count == 7,
        'strategy_count': count,
        'expected_count': 7
    }), 200
```

---

## END OF DOCUMENTATION

**Status**: ✅ API Endpoint Implemented and Ready for Use
**Location**: `src/backend/app/routes.py:4520`
**Tested**: Manual testing recommended
