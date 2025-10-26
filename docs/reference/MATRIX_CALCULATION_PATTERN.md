# Matrix Calculation Pattern (From Derik's System)

## Overview

The `role_competency_matrix` is a **calculated/derived** table, NOT a standalone table. It is computed from two source matrices:

1. **role_process_matrix** (Role × Process)
2. **process_competency_matrix** (Process × Competency)

## Calculation Formula

```
role_competency_value = role_process_value × process_competency_value
```

The multiplication result maps to specific competency levels:
- `0` → Not relevant
- `1` → Apply (anwenden)
- `2` → Understand (verstehen)
- `3` → Apply
- `4` → Apply
- `6` → Master (beherrschen)
- `-100` → Invalid combination

## Stored Procedure

### `update_role_competency_matrix(organization_id)`

**Purpose**: Recalculates the role_competency_matrix for a specific organization

**SQL Logic**:
```sql
DELETE FROM role_competency_matrix WHERE organization_id = _organization_id;

INSERT INTO role_competency_matrix (role_cluster_id, competency_id, role_competency_value, organization_id)
SELECT
    rpm.role_cluster_id,
    pcm.competency_id,
    MAX(
        CASE
            WHEN rpm.role_process_value * pcm.process_competency_value = 0 THEN 0
            WHEN rpm.role_process_value * pcm.process_competency_value = 1 THEN 1
            WHEN rpm.role_process_value * pcm.process_competency_value = 2 THEN 2
            WHEN rpm.role_process_value * pcm.process_competency_value = 3 THEN 3
            WHEN rpm.role_process_value * pcm.process_competency_value = 4 THEN 4
            WHEN rpm.role_process_value * pcm.process_competency_value = 6 THEN 6
            ELSE -100
        END
    ) AS role_competency_value,
    _organization_id
FROM role_process_matrix rpm
JOIN process_competency_matrix pcm ON rpm.iso_process_id = pcm.iso_process_id
WHERE rpm.organization_id = _organization_id
GROUP BY rpm.role_cluster_id, pcm.competency_id;
```

## When to Call Recalculation

### 1. When role_process_matrix is Updated

**Trigger**: Admin updates role-process matrix values for their organization

**Action**: Recalculate for THAT organization only

**Implementation** (from Derik's routes.py:250):
```python
@app.route('/api/role_process_matrix/bulk-update', methods=['PUT'])
def bulk_update_role_process_matrix():
    # ... update role_process_matrix ...
    db.session.commit()

    # Recalculate role-competency matrix for this organization
    db.session.execute(
        text('CALL update_role_competency_matrix(:org_id);'),
        {'org_id': organization_id}
    )
    db.session.commit()
```

### 2. When process_competency_matrix is Updated

**Trigger**: Admin updates process-competency matrix values (global)

**Action**: Recalculate for ALL organizations

**Reason**: process_competency_matrix is NOT organization-specific in Derik's schema

**Implementation** (from Derik's routes.py:322-328):
```python
@app.route('/api/process_competency_matrix/bulk-update', methods=['PUT'])
def bulk_update_process_competency_matrix():
    # ... update process_competency_matrix ...
    db.session.commit()

    # Recalculate for ALL organizations
    organizations = Organization.query.all()
    for org in organizations:
        db.session.execute(
            text('CALL update_role_competency_matrix(:org_id);'),
            {'org_id': org.id}
        )
    db.session.commit()
```

## Current Implementation Status

### ✅ Completed
- Created `role_competency_matrix` table
- Created `update_role_competency_matrix(org_id)` stored procedure
- Procedure correctly implements calculation logic from Derik's system

### ⚠️ Pending (When Admin UI is Built)
- Implement `/api/role_process_matrix/bulk-update` endpoint with recalculation
- Implement `/api/process_competency_matrix/bulk-update` endpoint with recalculation
- Frontend admin UI for editing matrices

## Testing the Calculation

Once you have competencies and process_competency_matrix data, test with:

```python
# Test recalculation for organization 1
cd src/backend
python -c "
from app import create_app
from models import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    # Recalculate for org 1
    db.session.execute(text('CALL update_role_competency_matrix(:org_id);'), {'org_id': 1})
    db.session.commit()

    # Check results
    count = db.session.execute(text('SELECT COUNT(*) FROM role_competency_matrix WHERE organization_id = 1;')).scalar()
    print(f'Generated {count} role-competency entries for org 1')
"
```

## Key Insights from Derik's System

1. **role_competency_matrix is NEVER directly edited** - it's always calculated
2. **No automatic triggers** - recalculation is called explicitly after updates
3. **Organization-scoped** - each organization has its own calculated matrix
4. **Formula is simple multiplication** - no complex algorithms, just value mapping

## References

- **Source**: `sesurveyapp-main/postgres-init/init.sql` lines 393-432
- **Implementation**: `sesurveyapp-main/app/routes.py` lines 250, 322-328
