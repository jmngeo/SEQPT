# Phase 2 Task 3: Learning Objectives API Documentation

**Version**: 1.0.0
**Date**: November 4, 2025
**Status**: Production Ready

---

## Overview

The Learning Objectives API provides 5 endpoints for generating, retrieving, and managing learning objectives for organizations based on their competency assessments.

**Base URL**: `http://localhost:5000/api`

**Authentication**: Currently no authentication required (add JWT in production)

---

## Endpoints

### 1. Check Prerequisites

Lightweight endpoint to check if an organization meets the requirements for generating learning objectives.

**Endpoint**: `GET /api/phase2/learning-objectives/<organization_id>/prerequisites`

**Use Case**: Frontend button validation (disable "Generate" button if prerequisites not met)

**Response (Success - 200)**:
```json
{
  "valid": true,
  "completion_rate": 100.0,
  "pathway": "ROLE_BASED",
  "selected_strategies_count": 2,
  "role_count": 3
}
```

**Response (Failure - 400)**:
```json
{
  "valid": false,
  "error": "Insufficient assessment data",
  "completion_rate": 45.0,
  "required_rate": 70.0
}
```

**Prerequisites**:
- At least 70% of users have completed assessments
- At least 1 learning strategy selected

---

### 2. Generate Learning Objectives

Main endpoint that orchestrates the complete learning objectives generation process.

**Endpoint**: `POST /api/phase2/learning-objectives/generate`

**Request Body**:
```json
{
  "organization_id": 28
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "pathway": "ROLE_BASED",
  "pathway_reason": "3 roles defined - using role-based approach",
  "completion_rate": 100.0,
  "role_count": 3,
  "roles": ["Systems Engineer", "Requirements Engineer", "Project Manager"],
  "selected_strategies": [
    {
      "id": 1,
      "name": "Foundation Workshop",
      "description": "Introductory SE fundamentals",
      "priority": 1
    }
  ],
  "learning_objectives_by_strategy": {
    "1": {
      "strategy_id": 1,
      "strategy_name": "Foundation Workshop",
      "requires_pmt": false,
      "pmt_customization_applied": false,
      "core_competencies": [
        {
          "competency_id": 1,
          "competency_name": "Systems Thinking",
          "note": "This core competency develops indirectly...",
          "status": "core_competency"
        }
      ],
      "trainable_competencies": [
        {
          "competency_id": 2,
          "competency_name": "Requirements Engineering",
          "current_level": 0,
          "target_level": 2,
          "gap": 2,
          "learning_objective": "Participants are able to...",
          "status": "training_required"
        }
      ],
      "summary": {
        "total_competencies": 14,
        "core_competencies_count": 4,
        "trainable_competencies_count": 10,
        "competencies_requiring_training": 3,
        "competencies_targets_achieved": 7
      }
    }
  },
  "strategy_validation": {
    "status": "adequate",
    "adequate": true,
    "...": "..."
  },
  "strategic_decisions": {
    "overall_action": "PROCEED",
    "...": "..."
  }
}
```

**Response (Error - 400)**:
```json
{
  "success": false,
  "error": "Insufficient assessment data",
  "error_type": "INSUFFICIENT_ASSESSMENTS",
  "details": {
    "completion_rate": 45.0,
    "required_rate": 70.0,
    "total_users": 10,
    "users_with_assessments": 4,
    "message": "At least 70% of users must complete assessment. Current: 45.0%"
  }
}
```

**Error Types**:
- `INSUFFICIENT_ASSESSMENTS` (400) - Less than 70% completion
- `NO_STRATEGIES` (400) - No learning strategies selected
- `ORGANIZATION_NOT_FOUND` (404) - Organization doesn't exist
- `INTERNAL_ERROR` (500) - Unexpected error

**Pathway Types**:
- `TASK_BASED` - Organization has 0 defined roles (low maturity)
- `ROLE_BASED` - Organization has 1+ defined roles (high maturity)

---

### 3. Get Learning Objectives

Retrieve previously generated learning objectives.

**Endpoint**: `GET /api/phase2/learning-objectives/<organization_id>`

**Query Parameters**:
- `regenerate` (optional) - If `true`, regenerate objectives instead of returning cached

**Response**: Same structure as `/generate` endpoint

**Note**: Currently always regenerates (no caching implemented yet)

---

### 4. Get PMT Context

Retrieve PMT (Processes, Methods, Tools) context for deep customization.

**Endpoint**: `GET /api/phase2/learning-objectives/<organization_id>/pmt-context`

**Response (200)**:
```json
{
  "organization_id": 28,
  "processes": "Requirements analysis, System design, Integration testing",
  "methods": "V-Model, Design Thinking, FMEA",
  "tools": "DOORS, Enterprise Architect, TestRail",
  "industry_specific_context": "Medical device development per ISO 13485",
  "is_complete": true,
  "created_at": "2025-11-04T12:00:00Z",
  "updated_at": "2025-11-04T14:30:00Z"
}
```

**PMT Context Usage**:
- Required for 2 specific strategies:
  - "Needs-based project-oriented training"
  - "Continuous support"
- Enables LLM-based deep customization of learning objectives
- Other 5 strategies use templates (no PMT needed)

---

### 5. Update PMT Context

Update PMT context for an organization.

**Endpoint**: `PATCH /api/phase2/learning-objectives/<organization_id>/pmt-context`

**Request Body**:
```json
{
  "processes": "Requirements analysis, System design, Integration testing",
  "methods": "V-Model, Design Thinking, FMEA",
  "tools": "DOORS, Enterprise Architect, TestRail",
  "industry_specific_context": "Medical device development per ISO 13485 and IEC 62304"
}
```

**Response (200)**:
```json
{
  "success": true,
  "organization_id": 28,
  "processes": "Requirements analysis, System design, Integration testing",
  "methods": "V-Model, Design Thinking, FMEA",
  "tools": "DOORS, Enterprise Architect, TestRail",
  "industry_specific_context": "Medical device development per ISO 13485 and IEC 62304",
  "is_complete": true,
  "updated_at": "2025-11-04T14:30:00Z"
}
```

**Notes**:
- All fields are optional - can update individual fields
- PMT context is created if it doesn't exist
- `is_complete` is `true` if all 4 fields are non-empty

---

### 6. Get Validation Results

Get strategy validation results (role-based pathways only).

**Endpoint**: `GET /api/phase2/learning-objectives/<organization_id>/validation`

**Response (Success - 200)**:
```json
{
  "success": true,
  "organization_id": 28,
  "pathway": "ROLE_BASED",
  "validation": {
    "status": "adequate",
    "adequate": true,
    "inadequate_strategies": [],
    "severity_counts": {
      "MINOR": 2,
      "MODERATE": 0,
      "SIGNIFICANT": 0
    }
  },
  "recommendations": {
    "overall_action": "PROCEED",
    "recommended_strategies": []
  }
}
```

**Response (Task-Based - 400)**:
```json
{
  "success": false,
  "error": "Validation layer only available for role-based pathways",
  "pathway": "TASK_BASED"
}
```

**Note**: Validation layer only exists for ROLE_BASED pathways

---

## Frontend Integration Example

```javascript
// Check prerequisites before enabling button
async function checkPrerequisites(orgId) {
  const response = await fetch(`/api/phase2/learning-objectives/${orgId}/prerequisites`);
  const data = await response.json();

  if (data.valid) {
    enableGenerateButton();
  } else {
    disableGenerateButton();
    showError(data.error);
  }
}

// Generate learning objectives
async function generateObjectives(orgId) {
  showLoading();

  const response = await fetch('/api/phase2/learning-objectives/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ organization_id: orgId })
  });

  const data = await response.json();

  hideLoading();

  if (data.success) {
    displayObjectives(data);
  } else {
    showError(data.error, data.details);
  }
}

// Update PMT context
async function updatePMTContext(orgId, pmtData) {
  const response = await fetch(`/api/phase2/learning-objectives/${orgId}/pmt-context`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(pmtData)
  });

  const data = await response.json();

  if (data.success) {
    showSuccess('PMT context updated');
    return data.is_complete;
  } else {
    showError(data.error);
    return false;
  }
}
```

---

## Testing

### Using curl:

**1. Check prerequisites**:
```bash
curl -X GET http://localhost:5000/api/phase2/learning-objectives/28/prerequisites
```

**2. Generate objectives**:
```bash
curl -X POST http://localhost:5000/api/phase2/learning-objectives/generate \
  -H "Content-Type: application/json" \
  -d '{"organization_id": 28}'
```

**3. Update PMT context**:
```bash
curl -X PATCH http://localhost:5000/api/phase2/learning-objectives/28/pmt-context \
  -H "Content-Type: application/json" \
  -d '{
    "processes": "Agile development, DevOps",
    "methods": "Scrum, Kanban",
    "tools": "JIRA, Git",
    "industry_specific_context": "Medical device development"
  }'
```

### Using Python test script:

```bash
# Test route registration
python test_api_routes_registration.py

# Test endpoints (requires Flask server running)
python test_api_endpoints.py
```

---

## Error Handling

All endpoints return consistent error format:

```json
{
  "success": false,
  "error": "Human-readable error message",
  "error_type": "ERROR_CODE",
  "details": {
    "...": "Additional context"
  }
}
```

**HTTP Status Codes**:
- `200` - Success
- `400` - Bad Request (invalid input, prerequisites not met)
- `404` - Not Found (organization doesn't exist)
- `500` - Internal Server Error

---

## Performance

**Expected Response Times**:
- Prerequisites check: ~50ms
- Get PMT context: ~20ms
- Update PMT context: ~100ms
- Generate objectives:
  - Task-based pathway: ~2-3 seconds
  - Role-based pathway: ~3-5 seconds
  - With LLM customization: +500-1000ms per competency

**Optimization Notes**:
- Consider adding caching for generated objectives
- Consider async generation for large organizations
- PMT context updates are fast (simple DB write)

---

## Future Enhancements

1. **Caching**: Store generated objectives in database for faster retrieval
2. **WebSocket**: Real-time progress updates during generation
3. **Batch Generation**: Generate for multiple organizations
4. **Export**: PDF/Excel export of learning objectives
5. **Authentication**: JWT-based authentication
6. **Rate Limiting**: Prevent abuse
7. **Audit Logging**: Track who generated what and when

---

## Support

For issues or questions, contact the development team or create an issue in the project repository.

**Documentation**: See `SESSION_HANDOVER.md` for implementation details

**Test Data**: Organization 28 (MedDevice Corp) has complete test data

---

**End of API Documentation**
