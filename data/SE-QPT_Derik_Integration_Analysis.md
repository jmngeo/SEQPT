# Complete Integration Analysis: SE-QPT + Derik's Competency Assessor

**Document Version:** 1.0
**Date:** 2025-09-30
**Author:** SE-QPT Development Team
**Purpose:** Comprehensive analysis of Docker integration, admin features, and system architecture

---

## Executive Summary

**Key Question:** Is using Derik's Docker setup alongside SE-QPT Docker a problem?

**Answer:** ✅ **NO - It's the RECOMMENDED approach**

### Why This Works:

1. ✅ **Shared PostgreSQL Database** - Both systems use the SAME PostgreSQL container
2. ✅ **Unified Docker Compose** - One orchestration file manages everything
3. ✅ **Proper Isolation** - Each service runs in its own container with clear boundaries
4. ✅ **Production-Ready** - Architecture scales well for deployment
5. ✅ **Modular Design** - Components can be independently updated and scaled

---

## Table of Contents

1. [Docker Architecture Analysis](#1-docker-architecture-analysis)
2. [Admin Features Deep Dive](#2-admin-features-deep-dive)
3. [Full Integration Workflow](#3-full-integration-workflow)
4. [Learning Objectives Generation](#4-learning-objectives-generation-with-archetypes)
5. [Database Schema Integration](#5-database-schema-integration)
6. [Deployment Recommendations](#6-deployment-recommendations)
7. [FAQ and Decision Points](#7-faq-and-decision-points)

---

## 1. Docker Architecture Analysis

### 1.1 Current State

**Your SE-QPT** (`docker-compose.yml` at root):
```yaml
services:
  postgres:        # Port 5432 - SQLite currently, will be PostgreSQL
  backend:         # Flask on 5000 - SE-QPT + integrated Derik routes
  frontend:        # Vue on 3000 - SE-QPT UI (Phases 1-3)
  chromadb:        # RAG vector DB on 8000 - For SE-QPT learning objectives
```

**Derik's Competency Assessor** (`src/competency_assessor/docker-compose.yml`):
```yaml
services:
  postgres:        # Port 5432 - WITH pre-loaded ISO processes, competencies
  backend:         # Flask on 5000 - Competency assessment routes
  frontend:        # Vue on 80 - Admin panel for matrix management
```

### 1.2 Integration Strategy: Unified Docker Compose (RECOMMENDED)

```yaml
version: '3.8'

services:
  # ============================================
  # SHARED DATABASE (used by both systems)
  # ============================================
  postgres:
    build:
      context: ./src/competency_assessor/postgres-init
      dockerfile: Dockerfile
    environment:
      POSTGRES_USER: seqpt_admin
      POSTGRES_PASSWORD: seqpt_secure_2025
      POSTGRES_DB: seqpt_unified
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      # Init script loads:
      # - 30 ISO processes (static)
      # - 16 SE competencies (editable)
      # - 14 role clusters (static)
      # - Default matrices
      # - Stored procedures for auto-recalculation
    networks:
      - seqpt_network

  # ============================================
  # SE-QPT BACKEND (Port 5000)
  # Single Flask app with integrated Derik routes
  # ============================================
  seqpt_backend:
    build:
      context: .
      dockerfile: deployment/docker/Dockerfile.backend
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://seqpt_admin:seqpt_secure_2025@postgres:5432/seqpt_unified
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - FLASK_ENV=production
      - DERIK_INTEGRATION_ENABLED=true
    depends_on:
      - postgres
      - chromadb
    volumes:
      - ./src/backend:/app/src/backend
      - ./src/competency_assessor:/app/src/competency_assessor  # Mount Derik's code
      - ./data:/app/data
    networks:
      - seqpt_network

  # ============================================
  # SE-QPT FRONTEND (Port 3000)
  # Employee/Admin interface for qualification planning
  # ============================================
  seqpt_frontend:
    build:
      context: .
      dockerfile: deployment/docker/Dockerfile.frontend
    ports:
      - "3000:3000"
    environment:
      - VITE_API_URL=http://seqpt_backend:5000
    depends_on:
      - seqpt_backend
    networks:
      - seqpt_network

  # ============================================
  # DERIK ADMIN FRONTEND (Port 8080)
  # Optional: Advanced matrix management
  # ============================================
  derik_admin_frontend:
    build:
      context: ./src/competency_assessor
      dockerfile: Dockerfile.frontend
    ports:
      - "8080:80"
    environment:
      - VUE_APP_API_URL=http://seqpt_backend:5000
    depends_on:
      - seqpt_backend
    networks:
      - seqpt_network

  # ============================================
  # CHROMADB (RAG Vector Store for SE-QPT)
  # For company-specific learning objectives
  # ============================================
  chromadb:
    image: ghcr.io/chroma-core/chroma:latest
    ports:
      - "8000:8000"
    volumes:
      - chromadb_data:/chroma/chroma
    networks:
      - seqpt_network

networks:
  seqpt_network:
    driver: bridge

volumes:
  postgres_data:
  chromadb_data:
```

### 1.3 Why This Architecture Works

#### **Single Database, Multiple Schemas:**

**SE-QPT Tables:**
- `questionnaire_responses` - Phase 1 maturity/archetype responses
- `assessments` - Overall assessment tracking
- `rag_context` - Company-specific RAG data
- `learning_objectives` - Generated objectives
- `module_selections` - Qualification module choices

**Derik Tables (30+ tables):**
- `iso_processes` - 30 standardized ISO/IEC 15288 processes
- `competencies` - 16 SE competencies
- `competency_indicators` - Level definitions (Know, Understand, Apply, Master)
- `role_clusters` - 14 predefined role clusters
- `role_process_matrix` - Organization-specific role-process mappings
- `process_competency_matrix` - System-wide process-competency mappings
- `role_competency_matrix` - Auto-calculated from above two matrices
- `organization` - Multi-tenant support
- `user_competency_survey_results` - Assessment responses

**No Conflicts:** Different table namespaces, no overlapping names

#### **Single Backend Process:**

```python
# SE-QPT Flask app (app.py)
from flask import Flask
from seqpt_routes import seqpt_bp
from src.competency_assessor.app.routes import main as derik_bp

app = Flask(__name__)

# SE-QPT routes: /api/questionnaires, /api/assessments, etc.
app.register_blueprint(seqpt_bp, url_prefix='/api')

# Derik routes: /api/derik/identify-processes, /api/derik/competencies, etc.
app.register_blueprint(derik_bp, url_prefix='/api/derik')

# All API calls go through ONE backend on port 5000
```

#### **Two Frontend Interfaces:**

1. **SE-QPT Frontend (Port 3000):**
   - Employee/admin qualification planning
   - Phase 1: Maturity assessment + Archetype selection
   - Phase 2: Competency assessment (uses Derik's questionnaire)
   - Phase 3: Module selection + Learning plan generation

2. **Derik Admin Frontend (Port 8080) - OPTIONAL:**
   - Advanced matrix management
   - Create/edit organizations
   - Customize Role-Process Matrix per organization
   - Configure Process-Competency Matrix (affects all orgs)
   - View survey results and analytics

---

## 2. Admin Features Deep Dive

### 2.1 View-Only (Read-Only) Features

#### **A) View ISO Processes** (`ISOProcess.vue`)

**Purpose:** Transparency - Show standardized ISO/IEC 15288:2023 processes

**Features:**
- Displays 30 processes with names and descriptions
- Read-only - these are standardized and cannot be edited
- Backend endpoint: `GET /api/derik/iso_processes`

**Example Processes:**
- Requirements Definition
- Architecture Definition
- Implementation
- Verification
- Validation
- Transition
- Operation
- Maintenance
- etc.

#### **B) View Role Clusters** (`RoleClusters.vue`)

**Purpose:** Show predefined role clusters

**Features:**
- Displays 14 role clusters with descriptions
- Read-only - standardized roles
- Backend endpoint: `GET /api/derik/roles`

**Example Roles:**
- Systems Architect
- Requirements Engineer
- Systems Engineer
- Test Engineer
- Project Manager
- Product Manager
- etc.

#### **C) View Role-Competency Matrix** (`RoleCompetencyMatrixView.vue`)

**Purpose:** Display automatically calculated competency requirements per role

**Features:**
- **Read-only** - values are auto-calculated
- Shows required competency levels (0, 1, 2, 4, 6) for each role
- Updates automatically when source matrices change
- Backend endpoint: `GET /api/derik/role_competency_matrix/{org_id}`

**Calculation Formula:**
```
Role_Competency[role][competency] = MAX(
    Role_Process[role][process] × Process_Competency[process][competency]
)
```

### 2.2 Editable (CRUD) Features

#### **A) Manage Competencies** (`CompetencyCrud.vue`)

**Purpose:** Customize the 16 SE competencies

**Features:**
- Create/Update/Delete competencies
- Edit: Area, Name, Description, "Why it matters"
- Backend: `/competencies` endpoints (routes.py:47-96)

**Use Case:** Customize competency framework for your organization

**16 SE Competencies (Default from Könemann et al.):**

**Core Competencies:**
1. Systemic thinking
2. System modeling and analysis
3. Consideration of system life cycle phases
4. Customer benefit orientation

**Professional Competencies:**
5. Requirements management
6. System architecture design
7. Implementation and integration
8. System validation and verification
9. Interface management
10. Consideration of dependencies and risks

**Social/Personal Competencies:**
11. Communication and cooperation
12. Conflict management
13. Decision-making competence

**Management Competencies:**
14. Systems leadership
15. Systems engineering management
16. Resource and project management

#### **B) Manage Competency Indicators** (`CompetencyIndicatorCrud.vue`)

**Purpose:** Define proficiency criteria for each competency level

**Features:**
- Create/Update/Delete indicators
- Define criteria for: Knowing (1), Understanding (2), Applying (3-4), Mastering (6)
- Backend: `/competency_indicators` endpoints

**Example for "Systems Thinking":**
- **Level 1 (Know):** "Knows the interrelationships of their system and system boundaries"
- **Level 2 (Understand):** "Understands the interaction of components that make up the system"
- **Level 4 (Apply):** "Can analyze existing system and derive continuous improvements"
- **Level 6 (Master):** "Can bring systems thinking into the company and inspire others"

#### **C) Configure Role-Process Matrix** (`RoleProcessMatrixCrud.vue`) ⭐ **MOST IMPORTANT**

**Purpose:** Customize how roles interact with ISO processes per organization

**Features:**
- **Organization-specific** customization
- Select organization → Select role → Define involvement levels
- Involvement levels:
  - **0** = Not Relevant
  - **1** = Supporting (assists in the process)
  - **2** = Responsible (directly executes or leads)
  - **3** = Designing (defines or improves workflows)
- Backend: `PUT /api/derik/role_process_matrix/bulk` (routes.py:229-255)
- **Triggers:** Calls `update_role_competency_matrix(org_id)` stored procedure

**Use Case:** Customize role requirements per organization

**Example:**
- Organization: "AutoTech GmbH"
- Role: "Systems Architect"
- Process: "Architecture Definition" → Involvement = **3** (Designing)
- Process: "Requirements Definition" → Involvement = **2** (Responsible)
- Process: "Implementation" → Involvement = **1** (Supporting)

**After saving:** Role-Competency Matrix automatically recalculates for AutoTech

#### **D) Configure Process-Competency Matrix** (`ProcessCompetencyMatrixCrud.vue`) ⭐ **CRITICAL**

**Purpose:** Define which competencies are needed for each ISO process

**Features:**
- **System-wide** configuration (affects all organizations)
- Maps ISO processes to competencies with requirement levels:
  - **0** = Not Useful
  - **1** = Useful (nice to have)
  - **2** = Necessary (required)
- Backend: `PUT /api/derik/process_competency_matrix/bulk` (routes.py:300-330)
- **Triggers:** Calls `update_role_competency_matrix()` for **ALL** organizations

**Use Case:** Define which competencies are needed for each process

**Example:**
- Process: "Requirements Definition"
- Competency: "Requirements Management" → Level = **2** (Necessary)
- Competency: "Communication and Cooperation" → Level = **2** (Necessary)
- Competency: "Systems Thinking" → Level = **1** (Useful)

**After saving:** ALL organizations' Role-Competency Matrices recalculate

#### **E) Manage Organizations** (`OrganizationCrud.vue`)

**Purpose:** Multi-tenant support - Create and manage multiple organizations

**Features:**
- Create/Update/Delete organizations
- Each organization gets unique key
- Backend: `/organizations` endpoints
- **Auto-generates:** Default Role-Process and Role-Competency matrices on creation

**Use Case:** Support multiple companies/departments with unique requirements

**Example:**
- Create: `name="AutoTech GmbH"`, `key="autotech_2025"`
- System automatically:
  - Copies default Role-Process Matrix
  - Calculates Role-Competency Matrix
  - Organization ready for customization

#### **F) View Survey Results** (`SurveyResultsAdmin.vue`)

**Purpose:** Organizational analytics and competency gap analysis

**Features:**
- View all user assessments
- Filter by organization
- Aggregate competency gaps
- Backend: `/survey_results_admin` endpoint

**Use Case:** Identify organizational training needs

### 2.3 Auto-Recalculation Mechanism

**Stored Procedure:** `update_role_competency_matrix(organization_id)`
**Location:** `src/competency_assessor/postgres-init/filtered_init.sql:391-430`

#### **How It Works:**

**Trigger 1: When Role-Process Matrix is Updated**
```python
# routes.py:250
db.session.execute(
    text('CALL update_role_competency_matrix(:org_id);'),
    {'org_id': organization_id}
)
```
- Recalculates **only that organization's** Role-Competency Matrix
- Fast, isolated operation

**Trigger 2: When Process-Competency Matrix is Updated**
```python
# routes.py:325
for org in all_organizations:
    db.session.execute(
        text('CALL update_role_competency_matrix(:org_id);'),
        {'org_id': org['id']}
    )
```
- Recalculates **ALL organizations** (loops through all)
- Ensures consistency across entire system

#### **Calculation Logic:**

```sql
-- Simplified version
INSERT INTO role_competency_matrix (role_cluster_id, competency_id, role_competency_value)
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
            ELSE -100  -- Invalid
        END
    ) AS role_competency_value
FROM role_process_matrix rpm
JOIN process_competency_matrix pcm ON rpm.iso_process_id = pcm.iso_process_id
WHERE rpm.organization_id = :org_id
GROUP BY rpm.role_cluster_id, pcm.competency_id;
```

#### **Example Calculation:**

**Inputs:**
- Role: "Systems Architect"
- Process: "Architecture Definition"
  - Role involvement: **3** (Designing)
- Competency: "Systems Thinking"
  - Process requirement: **2** (Necessary)

**Calculation:**
```
Role_Competency = 3 × 2 = 6 (Mastering)
```

**Result:** Systems Architect needs level **6** (Mastery) in Systems Thinking

---

## 3. Full Integration Workflow

### 3.1 Phase 1: Maturity Assessment + Archetype Selection (SE-QPT)

**Flow:**
1. Admin/Employee logs into SE-QPT (http://localhost:3000)
2. Completes maturity questionnaire (33 questions)
3. Completes archetype questionnaire (5 questions)
4. SE-QPT calculates:
   - Maturity score (0-100%)
   - Qualification archetype (e.g., "SE for Managers")
5. Stores in SE-QPT database: `questionnaire_responses` table

**Output:** `qualification_archetype` (string)

**Qualification Archetypes:**
1. Common Basic Understanding
2. SE for Managers
3. Orientation in Pilot Project
4. Needs-Based, Project-Oriented Training
5. Continuous Support
6. Train the Trainer

### 3.2 Phase 2.1: Role Mapping (Derik Integration)

**Three Pathways:**

#### **Option A: Role-Based Assessment**

```python
# User selects from 14 predefined roles
POST /api/seqpt/phase2/role-based
{
  "user_id": "emp_456",
  "organization_key": "autotech_2025",
  "selected_roles": ["Systems Architect", "Requirements Engineer"]
}

# SE-QPT calls Derik's endpoint
GET /api/derik/role_competency_matrix/autotech_2025

# Returns required competencies for selected roles
# If multiple roles, takes MAX level across all roles
```

#### **Option B: Task-Based Assessment (RAG-LLM)**

```python
# User describes job tasks
POST /api/derik/public/identify-processes
{
  "job_description": "I define system requirements, coordinate with stakeholders,
                      create architecture models, and lead design reviews."
}

# Derik's RAG pipeline processes:
# 1. Validates and translates input (if non-English)
# 2. Pre-reasons with LLM (creative step, narrows search space)
# 3. Retrieves from FAISS vector store (ISO process descriptions)
# 4. LLM classifies involvement (Responsible/Supporting/Designing)

# Returns identified ISO processes
{
  "identified_processes": [
    "Requirements Definition",
    "Stakeholder Needs and Requirements",
    "System Architecture Definition",
    "Design Definition"
  ],
  "confidence_scores": {
    "Requirements Definition": 0.92,
    "Architecture Definition": 0.88,
    ...
  },
  "reasoning": "Identified using RAG-LLM pipeline"
}

# SE-QPT then:
# 1. Creates temporary Role-Process entry for "unknown role"
# 2. Multiplies by Process-Competency Matrix
# 3. Calculates required competencies
```

#### **Option C: Full Comprehensive Assessment**

```python
# User completes all 16 competencies without role constraints
# System recommends best-fit roles using distance metrics

POST /api/derik/public/recommend-roles
{
  "user_competency_profile": {
    "systems_thinking": 4,
    "requirements_mgmt": 6,
    "architecture_design": 5,
    ...
  },
  "organization_key": "autotech_2025"
}

# Returns role recommendations
{
  "recommended_roles": [
    {"role": "Requirements Engineer", "match": 92%, "distance": 2.3},
    {"role": "Systems Architect", "match": 85%, "distance": 3.1}
  ]
}
```

### 3.3 Phase 2.2: Competency Assessment (Derik Integration)

**Derik's 16-Question Survey:**

```python
# User completes Derik's validated questionnaire
POST /api/derik/competency_survey
{
  "user_id": "emp_456",
  "organization_key": "autotech_2025",
  "responses": {
    "systems_thinking": 4,      # Self-assessed: Apply level
    "requirements_mgmt": 2,     # Self-assessed: Understand level
    "architecture_design": 4,   # Self-assessed: Apply level
    ...
  }
}

# Derik calculates gaps
recorded_level = user_survey_response  # Self-assessment
required_level = role_competency_matrix[user_role][competency]  # From matrix

gap = required_level - recorded_level  # Positive = needs training

# Returns gap analysis
{
  "competency_gaps": [
    {
      "competency": "requirements_mgmt",
      "recorded_level": 2,
      "required_level": 6,
      "gap": 4,
      "priority": "critical"
    },
    {
      "competency": "systems_thinking",
      "recorded_level": 4,
      "required_level": 6,
      "gap": 2,
      "priority": "high"
    }
  ]
}
```

---

## 4. Learning Objectives Generation with Archetypes

### 4.1 Archetype-Competency Matrix

**Source:** Excel file `Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx`, Sheet: "Learning Objectives"

**Qualification Archetypes and Their Competency Levels:**

| Competency | Common Basic Understanding | SE for Managers | Orientation in Pilot Project | Needs-Based, Project-Oriented Training | Continuous Support | Train the Trainer |
|------------|---------------------------|-----------------|------------------------------|----------------------------------------|-------------------|-------------------|
| **Core Competencies** |
| Systemic thinking | 2 | 4 | 4 | 4 | 2 | 6 |
| System modeling and analysis | 2 | 1 | 4 | 4 | 4 | 6 |
| Consideration of system life cycle phases | 2 | 1 | 4 | 4 | 4 | 6 |
| Customer benefit orientation | 2 | 2 | 4 | 4 | 2 | 6 |
| **Professional Competencies** |
| Requirements management | 2 | 1 | 4 | 4 | 4 | 6 |
| System architecture design | 2 | 1 | 4 | 4 | 4 | 6 |
| Implementation and integration | 2 | 1 | 4 | 4 | 4 | 6 |
| System validation and verification | 2 | 1 | 4 | 4 | 4 | 6 |
| Interface management | 2 | 1 | 4 | 4 | 4 | 6 |
| Consideration of dependencies and risks | 2 | 1 | 4 | 4 | 4 | 6 |
| **Social/Personal Competencies** |
| Communication and cooperation | 2 | 4 | 4 | 4 | 2 | 6 |
| Conflict management | 1 | 4 | 2 | 2 | 1 | 6 |
| Decision-making competence | 2 | 4 | 4 | 4 | 2 | 6 |
| **Management Competencies** |
| Systems leadership | 1 | 4 | 2 | 2 | 1 | 6 |
| Systems engineering management | 2 | 4 | 4 | 4 | 2 | 6 |
| Resource and project management | 1 | 4 | 2 | 2 | 1 | 6 |

**Level Meanings:**
- **0** = Not Relevant
- **1** = Know (awareness)
- **2** = Understand (comprehension)
- **4** = Apply (practical use)
- **6** = Master (expert, can teach others)

### 4.2 Learning Objective Generation Algorithm

**Updated Phase 2.2 Process:**

```python
# SE-QPT generates learning objectives using THREE inputs:
# 1. Competency gaps (from Derik)
# 2. Qualification archetype (from Phase 1)
# 3. Company context (PMT data)

def generate_learning_objectives(
    competency_gaps: dict,
    qualification_archetype: str,
    company_context: dict,
    user_profile: dict
) -> list:
    """
    Generate SMART learning objectives for training modules.

    Args:
        competency_gaps: From Derik's competency assessment
        qualification_archetype: From SE-QPT Phase 1 (e.g., "SE for Managers")
        company_context: Company-specific PMT data from RAG
        user_profile: User role, department, experience level

    Returns:
        List of learning objectives with modules
    """

    objectives = []

    # Get archetype-specific competency targets
    archetype_targets = get_archetype_competency_matrix(qualification_archetype)

    for competency, gap_data in competency_gaps.items():
        if gap_data['gap'] > 0:
            # Get archetype target level
            archetype_target = archetype_targets[competency]

            # Get role-specific requirement
            role_requirement = gap_data['required_level']

            # Target level is MINIMUM of both
            target_level = min(archetype_target, role_requirement)

            # Generate objective using RAG-LLM
            objective = se_qpt_rag.generate_objective(
                competency=competency,
                current_level=gap_data['recorded_level'],
                target_level=target_level,
                archetype=qualification_archetype,
                company_context=company_context,
                user_profile=user_profile
            )

            objectives.append(objective)

    return objectives
```

### 4.3 Learning Objective Template (from Excel)

**SMART Formulation Guidelines:**

✅ **Specific:** Clear, well-defined outcome
✅ **Measurable:** Observable through "by" (measurability clause)
✅ **Achievable:** Realistic based on current level
✅ **Relevant:** Connected to role requirements
✅ **Time-bound:** Tied to training duration

**Template Structure:**

```
At the end of [training duration], the participant [competency level verb]
[competency focus] by [measurable criteria], so that/in order to [benefit/purpose].
```

**Level-Specific Verbs:**
- **Level 1 (Know):** knows, recognizes, identifies, lists
- **Level 2 (Understand):** understands, explains, describes, interprets
- **Level 4 (Apply):** applies, analyzes, implements, solves
- **Level 6 (Master):** evaluates, creates, designs, leads, inspires

### 4.4 Example Learning Objective Generation

**Inputs:**
- **Competency:** Systems Thinking
- **Current Level:** 2 (Understand)
- **Role Requirement:** 6 (Master) - from Role-Competency Matrix
- **Archetype:** "SE for Managers"
- **Archetype Target:** 4 (Apply) - from Archetype-Competency Matrix
- **Final Target:** min(6, 4) = **4 (Apply)**
- **Company Context:** "Automotive company developing ADAS systems"

**Generated Learning Objective:**

```
At the end of the two-day workshop, the participant applies systems thinking
principles to analyze the ADAS system architecture by identifying system boundaries,
component interactions, and interface dependencies in a simulated system review,
in order to effectively lead cross-functional architecture discussions and contribute
to system design decisions in their role as Engineering Manager.

Measurable Success Criteria:
- Identifies at least 5 key system boundaries
- Maps 10+ component interactions correctly
- Documents 8+ critical interface dependencies
- Successfully completes simulated architecture review

Recommended Learning Formats (from archetype):
- Seminars/Webinars (initial concepts)
- Blended Learning (theory + practice)
- Coaching sessions (1-on-1 guidance)

Recommended Modules:
- Module SE-101: Fundamentals of Systems Thinking
- Module SE-205: System Architecture Principles
- Module SE-310: Interface Management in Complex Systems
```

### 4.5 Archetype-Specific Learning Paths

#### **Archetype 1: Common Basic Understanding**
- **Target:** Level 2 (Understanding) across most competencies
- **Focus:** Awareness and basic comprehension
- **Format:** Seminars, webinars, serious gaming
- **Duration:** Short (1-3 days)

#### **Archetype 2: SE for Managers**
- **Target:** Level 4 (Apply) for core/management, Level 1-2 for technical
- **Focus:** Leadership, communication, decision-making
- **Format:** Seminars, coaching, executive workshops
- **Duration:** Medium (5-10 days over 3 months)

#### **Archetype 3: Orientation in Pilot Project**
- **Target:** Level 4 (Apply) across all competencies
- **Focus:** Practical application in real projects
- **Format:** Training on the job, tutorials, coaching
- **Duration:** Long (3-6 months embedded in project)

#### **Archetype 4: Needs-Based, Project-Oriented Training**
- **Target:** Level 4 (Apply) with gaps filled
- **Focus:** Specific competency gaps for ongoing projects
- **Format:** Coaching, just-in-time training, tutorials
- **Duration:** Flexible (as needed)

#### **Archetype 5: Continuous Support**
- **Target:** Maintain Level 2-4, refresh knowledge
- **Focus:** Ongoing support, preventing skill decay
- **Format:** Regular refreshers, peer learning, communities of practice
- **Duration:** Continuous (quarterly sessions)

#### **Archetype 6: Train the Trainer**
- **Target:** Level 6 (Master) across all competencies
- **Focus:** Ability to teach, create content, mentor
- **Format:** Advanced workshops, experience-based learning, mentorship
- **Duration:** Extended (6-12 months)

---

## 5. Database Schema Integration

### 5.1 Derik's PostgreSQL Schema (30+ Tables)

#### **Static Reference Data:**

```sql
-- ISO/IEC 15288:2023 Processes (30 rows)
CREATE TABLE iso_processes (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    life_cycle_process_id INTEGER
);

-- SE Competencies (16 rows)
CREATE TABLE competency (
    id INTEGER PRIMARY KEY,
    competency_area VARCHAR(100),  -- Core, Professional, Social, Management
    competency_name VARCHAR(255),
    description TEXT,
    why_it_matters TEXT
);

-- Competency Level Indicators (~80 rows, ~5 per competency)
CREATE TABLE competency_indicators (
    id INTEGER PRIMARY KEY,
    competency_id INTEGER REFERENCES competency(id),
    level VARCHAR(20),  -- 'kennen', 'verstehen', 'anwenden', 'beherrschen'
    indicator_en TEXT
);

-- Role Clusters (14 rows)
CREATE TABLE role_cluster (
    id INTEGER PRIMARY KEY,
    role_cluster_name VARCHAR(255),
    role_cluster_description TEXT
);
```

#### **Organization-Specific Data:**

```sql
-- Multi-Tenant Support
CREATE TABLE organization (
    id INTEGER PRIMARY KEY,
    organization_name VARCHAR(255),
    organization_public_key VARCHAR(50) UNIQUE
);

-- Role-Process Matrix (organization-specific)
CREATE TABLE role_process_matrix (
    id INTEGER PRIMARY KEY,
    role_cluster_id INTEGER REFERENCES role_cluster(id),
    iso_process_id INTEGER REFERENCES iso_processes(id),
    role_process_value INTEGER,  -- 0, 1, 2, 3
    organization_id INTEGER REFERENCES organization(id)
);

-- Process-Competency Matrix (system-wide)
CREATE TABLE process_competency_matrix (
    id INTEGER PRIMARY KEY,
    iso_process_id INTEGER REFERENCES iso_processes(id),
    competency_id INTEGER REFERENCES competency(id),
    process_competency_value INTEGER  -- 0, 1, 2
);

-- Role-Competency Matrix (auto-calculated, organization-specific)
CREATE TABLE role_competency_matrix (
    id INTEGER PRIMARY KEY,
    role_cluster_id INTEGER REFERENCES role_cluster(id),
    competency_id INTEGER REFERENCES competency(id),
    role_competency_value INTEGER,  -- 0, 1, 2, 4, 6
    organization_id INTEGER REFERENCES organization(id)
);
```

#### **User Assessment Data:**

```sql
-- User Accounts
CREATE TABLE app_user (
    id INTEGER PRIMARY KEY,
    username VARCHAR(255),
    organization_id INTEGER REFERENCES organization(id)
);

-- Survey Responses
CREATE TABLE user_competency_survey_results (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES app_user(id),
    competency_id INTEGER REFERENCES competency(id),
    score INTEGER,  -- Self-assessed level
    survey_date TIMESTAMP
);

-- LLM-Generated Feedback
CREATE TABLE user_competency_survey_feedback (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES app_user(id),
    feedback_text TEXT,
    generated_at TIMESTAMP
);
```

### 5.2 SE-QPT's Additional Tables

```sql
-- Phase 1: Maturity & Archetype
CREATE TABLE questionnaire_responses (
    uuid UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    questionnaire_type VARCHAR(50),  -- 'maturity', 'archetype'
    responses JSONB,
    computed_archetype JSONB,  -- Stores archetype selection result
    status VARCHAR(20),
    created_at TIMESTAMP
);

-- Overall Assessment Tracking
CREATE TABLE assessments (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    organization_id UUID REFERENCES organization(id),
    phase1_completed BOOLEAN,
    phase2_completed BOOLEAN,
    phase3_completed BOOLEAN,
    qualification_archetype VARCHAR(100),
    created_at TIMESTAMP
);

-- Company-Specific RAG Context
CREATE TABLE rag_context (
    id UUID PRIMARY KEY,
    organization_id UUID REFERENCES organization(id),
    pmt_data JSONB,  -- Processes, Methods, Tools
    industry_sector VARCHAR(100),
    company_size VARCHAR(50)
);

-- Generated Learning Objectives
CREATE TABLE learning_objectives (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    competency_id INTEGER,  -- References Derik's competency table
    current_level INTEGER,
    target_level INTEGER,
    archetype_target INTEGER,  -- From archetype-competency matrix
    objective_text TEXT,
    measurable_criteria JSONB,
    recommended_modules JSONB,
    created_at TIMESTAMP
);

-- Module Selections (Phase 3)
CREATE TABLE module_selections (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    selected_modules JSONB,
    learning_path JSONB,
    estimated_duration_hours INTEGER
);
```

### 5.3 Shared Tables Strategy

**Option A: Merge User Models**
```sql
-- Extend Derik's app_user table
ALTER TABLE app_user ADD COLUMN seqpt_assessment_id UUID;
ALTER TABLE app_user ADD COLUMN qualification_archetype VARCHAR(100);
```

**Option B: Separate User Tables with Foreign Key**
```sql
-- SE-QPT maintains its own users table
CREATE TABLE seqpt_users (
    id UUID PRIMARY KEY,
    derik_user_id INTEGER REFERENCES app_user(id),  -- Link to Derik
    ...
);
```

**Recommendation:** Option B for cleaner separation and easier maintenance

### 5.4 Stored Procedures

```sql
-- Auto-recalculate Role-Competency Matrix
CREATE PROCEDURE update_role_competency_matrix(IN _organization_id integer)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Delete existing entries
    DELETE FROM role_competency_matrix WHERE organization_id = _organization_id;

    -- Recalculate
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

    RAISE NOTICE 'Role-Competency matrix updated for organization_id %', _organization_id;
END $$;
```

---

## 6. Deployment Recommendations

### 6.1 Development Setup (Current)

#### **Option A: Local Development (No Full Docker)**

```bash
# Terminal 1: Start PostgreSQL only
cd src/competency_assessor
docker-compose up -d postgres

# Wait for PostgreSQL to initialize (loads ISO processes, competencies, etc.)

# Terminal 2: SE-QPT Backend
cd src/backend
export DATABASE_URL="postgresql://seqpt_admin:seqpt_pass@localhost:5432/seqpt_unified"
export OPENAI_API_KEY="your-key-here"
python app.py

# Terminal 3: SE-QPT Frontend
cd src/frontend
npm run dev

# Terminal 4: Derik Admin Frontend (optional, for matrix management)
cd src/competency_assessor/frontend
VUE_APP_API_URL=http://localhost:5000 npm run serve

# Access:
# - SE-QPT: http://localhost:3000
# - Derik Admin: http://localhost:8080
# - Backend API: http://localhost:5000
# - PostgreSQL: localhost:5432
```

#### **Option B: Full Docker Compose (Production-like)**

```bash
# Single command starts everything
docker-compose up -d

# Services start in order:
# 1. PostgreSQL (loads init script)
# 2. ChromaDB
# 3. SE-QPT Backend (waits for postgres)
# 4. SE-QPT Frontend
# 5. Derik Admin Frontend

# Access:
# - SE-QPT: http://localhost:3000
# - Derik Admin: http://localhost:8080
# - Backend API: http://localhost:5000

# View logs
docker-compose logs -f seqpt_backend

# Stop all services
docker-compose down

# Stop and remove volumes (fresh start)
docker-compose down -v
```

### 6.2 Production Deployment

#### **Cloud-Ready Architecture:**

```
Internet
    ↓
Load Balancer (HTTPS)
    ↓
┌─────────────────────────────────┐
│   SE-QPT Frontend (Container)   │
│   - Vue.js SPA                   │
│   - Nginx                        │
│   - Port 3000 → 443              │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│  SE-QPT Backend (Container)     │
│  - Flask + Gunicorn              │
│  - Integrated Derik Routes       │
│  - Port 5000                     │
└─────────────────────────────────┘
    ↓                          ↓
┌──────────────────┐    ┌──────────────────┐
│   PostgreSQL     │    │    ChromaDB      │
│  (Managed RDS)   │    │   (Container)    │
│  Port 5432       │    │   Port 8000      │
└──────────────────┘    └──────────────────┘
```

#### **Environment Variables (Production):**

```bash
# .env.production
DATABASE_URL=postgresql://user:pass@prod-db.region.rds.amazonaws.com:5432/seqpt_prod
OPENAI_API_KEY=sk-prod-xxxxx
FLASK_ENV=production
SECRET_KEY=<strong-random-key>
CORS_ORIGINS=https://seqpt.yourdomain.com
ALLOWED_HOSTS=seqpt.yourdomain.com

# SSL/TLS
SSL_CERT_PATH=/etc/ssl/certs/seqpt.crt
SSL_KEY_PATH=/etc/ssl/private/seqpt.key

# Logging
LOG_LEVEL=INFO
SENTRY_DSN=<sentry-url>

# Rate Limiting
RATE_LIMIT_ENABLED=true
MAX_REQUESTS_PER_MINUTE=60
```

#### **Docker Compose for Production:**

```yaml
version: '3.8'

services:
  seqpt_backend:
    image: seqpt-backend:${VERSION}
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
        max_attempts: 3
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # ... other services
```

#### **Kubernetes Deployment (Optional):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: seqpt-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: seqpt-backend
  template:
    metadata:
      labels:
        app: seqpt-backend
    spec:
      containers:
      - name: seqpt-backend
        image: seqpt-backend:latest
        ports:
        - containerPort: 5000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: seqpt-secrets
              key: database-url
        resources:
          limits:
            memory: "2Gi"
            cpu: "1000m"
          requests:
            memory: "1Gi"
            cpu: "500m"
```

### 6.3 Monitoring and Observability

```python
# app.py - Add monitoring
from prometheus_flask_exporter import PrometheusMetrics
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Instrument Flask
FlaskInstrumentor().instrument_app(app)

# Custom metrics
competency_assessments_total = metrics.counter(
    'competency_assessments_total',
    'Total number of competency assessments completed'
)

learning_objectives_generated = metrics.counter(
    'learning_objectives_generated',
    'Total learning objectives generated'
)
```

---

## 7. FAQ and Decision Points

### Q1: "Would using Derik's Docker setup be a problem when packaging SE-QPT?"

**Answer: NO - It's actually the IDEAL approach.**

**Reasons:**
1. ✅ **Single Database Container** - No duplication, shared PostgreSQL
2. ✅ **Modular Services** - Each component independently scalable
3. ✅ **Standard Practices** - Multi-service orchestration is industry standard
4. ✅ **Production-Ready** - Works with Kubernetes, AWS ECS, Azure Containers
5. ✅ **Cost-Effective** - One database instance instead of two

### Q2: "How do admin features integrate with SE-QPT?"

**Answer: Two-Tier Admin Structure**

**Tier 1: SE-QPT Admins (Basic)**
- Access through SE-QPT Frontend (http://localhost:3000/admin)
- Can view organization progress
- Can view employee assessments
- Can generate organizational reports
- **Cannot** modify matrices

**Tier 2: Super Admins (Advanced)**
- Access through Derik Admin Panel (http://localhost:8080/admin)
- Can customize Role-Process Matrix per organization
- Can configure Process-Competency Matrix (affects all orgs)
- Can manage organizations
- Can view detailed survey results

**Recommendation:** Most admins only need Tier 1. Tier 2 reserved for SE experts.

### Q3: "How does qualification archetype influence learning objectives?"

**Answer: Three-Way Integration**

Learning objectives are generated using:
1. **Competency Gaps** (from Derik's assessment)
2. **Qualification Archetype** (from SE-QPT Phase 1)
3. **Company Context** (from SE-QPT RAG)

**Target Level Calculation:**
```
Target = MIN(role_requirement, archetype_target)
```

**Example:**
- Role requires: Systems Thinking Level 6 (Master)
- Archetype targets: Level 4 (Apply) for "SE for Managers"
- **Final Target:** Level 4 (Apply)
- **Rationale:** Manager doesn't need mastery, just application

### Q4: "Can we use separate databases instead of shared PostgreSQL?"

**Answer: Possible but NOT recommended**

**Issues:**
- Duplicate data (organizations, users)
- Complex synchronization logic
- Increased maintenance overhead
- Higher costs
- Data consistency challenges

**Recommendation:** Use shared PostgreSQL with proper schema separation

### Q5: "How to handle migrations when Derik's schema changes?"

**Answer: Version-Controlled Migrations**

```bash
# Derik updates (rare, mostly static data)
src/competency_assessor/postgres-init/filtered_init.sql

# SE-QPT migrations
src/backend/migrations/
  - 001_initial_seqpt_tables.sql
  - 002_add_learning_objectives.sql
  - 003_archetype_targets.sql

# Run migrations
cd src/backend
flask db upgrade
```

**Strategy:** Keep Derik's schema unchanged, extend with SE-QPT tables

### Q6: "Can employees access Derik's admin panel?"

**Answer: No - Implement role-based access control (RBAC)**

```python
# app.py
from functools import wraps
from flask import abort

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_admin:
            abort(403)
        return f(*args, **kwargs)
    return decorated_function

@app.route('/api/derik/admin/matrix', methods=['PUT'])
@admin_required
def update_matrix():
    # Only admins can access
    pass
```

### Q7: "How to test RAG-LLM without Docker?"

**Answer: Minimal PostgreSQL Setup**

```bash
# Option 1: Docker PostgreSQL only
docker run -d \
  -p 5432:5432 \
  -e POSTGRES_DB=seqpt_test \
  -e POSTGRES_USER=test \
  -e POSTGRES_PASSWORD=test \
  postgres:15

# Load only ISO processes (CSV import)
psql -U test -d seqpt_test -f minimal_iso_processes.sql

# Option 2: JSON file (simpler, no database)
# Modify llm_process_identification_pipeline.py to read from JSON
```

---

## 8. Next Steps

### Immediate Actions:

1. ✅ **Start Docker Desktop**
2. ✅ **Start PostgreSQL Container**
   ```bash
   cd src/competency_assessor
   docker-compose up -d postgres
   ```
3. ✅ **Configure Environment Variables**
   ```bash
   # Update .env
   DATABASE_URL=postgresql://seqpt_admin:seqpt_pass@localhost:5432/seqpt_unified
   OPENAI_API_KEY=your-key
   ```
4. ✅ **Test RAG-LLM Pipeline**
   - Call `/api/derik/public/identify-processes`
   - Verify different job descriptions return different processes
5. ✅ **Test Admin Matrix Management**
   - Access Derik admin panel
   - Create test organization
   - Customize Role-Process Matrix
   - Verify auto-recalculation

### Phase Completion Checklist:

**Phase 1 Integration:**
- [ ] Maturity questionnaire working
- [ ] Archetype selection working
- [ ] Archetype stored in database
- [ ] Phase 1 → Phase 2 button enabled

**Phase 2 Integration:**
- [ ] Role-based assessment working
- [ ] Task-based assessment using RAG-LLM
- [ ] Competency survey working
- [ ] Gap analysis calculated
- [ ] Archetype-competency matrix loaded

**Phase 2.2 Innovation:**
- [ ] Learning objectives generated with archetype input
- [ ] Company context integrated
- [ ] SMART objectives validated
- [ ] Recommended modules suggested

**Admin Features:**
- [ ] Organization management working
- [ ] Role-Process Matrix customizable
- [ ] Process-Competency Matrix editable
- [ ] Auto-recalculation triggered
- [ ] Survey results viewable

---

## Appendix A: Quick Reference Commands

### Docker Commands:

```bash
# Start everything
docker-compose up -d

# View logs
docker-compose logs -f <service_name>

# Restart a service
docker-compose restart <service_name>

# Stop everything
docker-compose down

# Fresh start (delete volumes)
docker-compose down -v

# Check status
docker-compose ps
```

### Database Commands:

```bash
# Connect to PostgreSQL
docker exec -it <postgres_container_id> psql -U seqpt_admin -d seqpt_unified

# List tables
\dt

# View Role-Competency Matrix
SELECT * FROM role_competency_matrix WHERE organization_id = 1;

# Manually trigger recalculation
CALL update_role_competency_matrix(1);

# Export data
pg_dump -U seqpt_admin seqpt_unified > backup.sql
```

### API Testing:

```bash
# Test task-based assessment
curl -X POST http://localhost:5000/api/derik/public/identify-processes \
  -H "Content-Type: application/json" \
  -d '{"job_description": "I define system requirements and lead architecture reviews"}'

# Test role-based assessment
curl http://localhost:5000/api/derik/role_competency_matrix/1

# Test learning objective generation
curl -X POST http://localhost:5000/api/seqpt/learning-objectives \
  -H "Content-Type: application/json" \
  -d '{
    "competency_gaps": {...},
    "qualification_archetype": "SE for Managers",
    "organization_key": "autotech_2025"
  }'
```

---

## Appendix B: Architecture Decision Records (ADRs)

### ADR-001: Shared PostgreSQL Database

**Decision:** Use single PostgreSQL instance for both SE-QPT and Derik

**Context:** Need to integrate Derik's competency assessor into SE-QPT

**Alternatives:**
1. Separate databases with API synchronization
2. Shared database with merged schemas
3. Microservices with event-driven architecture

**Decision:** Shared database (Option 2)

**Rationale:**
- Simpler data consistency
- Lower operational complexity
- Single source of truth
- Cost-effective
- Standard for monolithic applications

**Consequences:**
- Need careful schema migration management
- Potential for schema conflicts (mitigated by prefixing)
- Tighter coupling (acceptable for MVP)

---

### ADR-002: Qualification Archetype Integration

**Decision:** Use archetype-competency matrix to cap learning objective targets

**Context:** Different archetypes have different learning goals (managers don't need mastery in all technical areas)

**Alternatives:**
1. Ignore archetypes, use only role requirements
2. Replace role requirements with archetype targets
3. Combine both using MIN function

**Decision:** Combine using MIN (Option 3)

**Rationale:**
- Respects both role needs and learning capacity
- Prevents overtraining managers
- Aligns with archetype definitions
- Maintains role-based rigor

**Consequences:**
- More complex target calculation
- Requires archetype-competency matrix maintenance
- Better learning experience

---

### ADR-003: Two-Frontend Architecture

**Decision:** Maintain both SE-QPT and Derik admin frontends

**Context:** Need admin matrix management but most users only need qualification planning

**Alternatives:**
1. Merge into single frontend
2. Keep separate frontends
3. Embed Derik admin into SE-QPT

**Decision:** Keep separate (Option 2)

**Rationale:**
- Separation of concerns
- Derik admin is complex, requires expertise
- Most admins don't need matrix management
- Easier to maintain independently

**Consequences:**
- Two UIs to maintain
- Potential confusion for super admins
- Better role separation

---

## Document Control

**Version History:**

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-09-30 | Initial comprehensive analysis | SE-QPT Team |

**Approval:**

- [ ] Technical Lead
- [ ] Product Owner
- [ ] DevOps Engineer

**Next Review Date:** 2025-10-15

---

**End of Document**
