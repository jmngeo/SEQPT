# SE-QPT System Design Summary
## Systems Engineering Qualification Planning Tool
### Design Document for Non-Technical Review

**Document Version:** 1.0
**Date:** October 14, 2025
**Author:** Jomon George
**Purpose:** Thesis Advisor Review - Product Validation
**Audience:** Non-software development stakeholders

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [What Problem Does SE-QPT Solve?](#what-problem-does-se-qpt-solve)
3. [Who Uses SE-QPT?](#who-uses-se-qpt)
4. [How Does SE-QPT Work?](#how-does-se-qpt-work)
5. [System Architecture Overview](#system-architecture-overview)
6. [Complete User Workflows](#complete-user-workflows)
7. [Key Features and Capabilities](#key-features-and-capabilities)
8. [Data and Privacy](#data-and-privacy)
9. [Validation and Correctness](#validation-and-correctness)

---

## Executive Summary

**SE-QPT (Systems Engineering Qualification Planning Tool)** is a web-based platform that helps organizations develop personalized training and qualification programs for their Systems Engineering (SE) teams.

### What Makes SE-QPT Unique?

1. **Organization-First Approach**: Assesses the organization's SE maturity level before individual competencies
2. **Adaptive Learning Paths**: Different training strategies based on organizational context
3. **Role-Aware Assessment**: Understands that different roles need different SE competencies
4. **Multi-Phase Process**: Systematic progression from organizational to individual assessment

### Core Value Proposition

Traditional SE training uses a "one-size-fits-all" approach. SE-QPT recognizes that:
- A startup needs different SE training than an established enterprise
- Managers need different SE skills than engineers
- Training strategies should match organizational readiness

---

## What Problem Does SE-QPT Solve?

### Current Situation (Without SE-QPT)

Organizations struggle to answer:
- "What SE training does our organization need?"
- "Which employees need which competencies?"
- "Should we focus on basic awareness or advanced skills?"
- "How do we personalize training for different roles?"

### Traditional Approach Problems

```
Manual Planning Process:
┌─────────────────────────────────────────┐
│ HR Manager or SE Lead:                  │
│ 1. Guesses at training needs            │
│ 2. Selects generic SE courses           │
│ 3. Sends everyone to same training      │
│ 4. No consideration of org maturity     │
│ 5. No role-specific customization       │
└─────────────────────────────────────────┘
                 ↓
        Results in:
        - Wasted training budget
        - Irrelevant content for many participants
        - Low engagement and application
        - No strategic alignment
```

### SE-QPT Solution

```
Systematic Planning Process:
┌─────────────────────────────────────────┐
│ SE-QPT Assessment:                      │
│ 1. Measures organizational maturity     │
│ 2. Selects appropriate strategy         │
│ 3. Identifies role-specific gaps        │
│ 4. Generates learning objectives plans  │
│ 5. Prioritizes critical competencies    │
└─────────────────────────────────────────┘
                 ↓
        Results in:
        - Targeted, effective training
        - Role-appropriate content
        - Strategic resource allocation
        - Measurable competency development
```

---

## Who Uses SE-QPT?

### User Types

SE-QPT has **two types of users** with different roles and permissions:

#### 1. Administrator (Organizational Leader)

**Who:**
- SE Manager
- Training Manager
- Department Head
- Chief Engineer

**Responsibilities:**
- Complete organizational assessments
- Define organization's SE maturity level
- Select qualification strategy (archetype)
- View team member progress
- Generate organizational reports

**What They Can Do:**
- Access all system features
- Complete Phase 1 (Organizational Assessment)
- Complete Phase 2 (Personal Competency Assessment)
- View all employees' assessment results
- Generate organization-level learning plans

#### 2. Employee (Team Member)

**Who:**
- Systems Engineers
- Requirements Engineers
- Project Managers
- Technical Team Members

**Responsibilities:**
- Complete personal competency assessment
- View their own results and learning plans
- Track personal development progress

**What They Can Do:**
- View organization's Phase 1 results (read-only)
- Complete Phase 2 (Personal Competency Assessment)
- View their own competency gaps
- Access their personalized learning plan
- Track their progress

### User Registration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    ADMINISTRATOR PATH                       │
└─────────────────────────────────────────────────────────────┘
   1. Register new account (username/password)
   2. Create organization profile
   3. System generates unique Organization Code (e.g., "ABC123")
   4. Complete Phase 1 assessments
   5. Share Organization Code with team members

                            ↓

┌─────────────────────────────────────────────────────────────┐
│                      EMPLOYEE PATH                          │
└─────────────────────────────────────────────────────────────┘
   1. Register with Organization Code
   2. Automatically join organization
   3. View organization's Phase 1 results (read-only)
   4. Complete Phase 2 assessment
   5. Receive personalized learning plan
```

**Key Design Decision:** Organization Code system enables self-service employee onboarding without requiring administrator to manually invite each person.

---

## How Does SE-QPT Work?

SE-QPT uses a **two-phase assessment approach**:

### Phase 1: Organizational Analysis (Admin-Only)

**Purpose:** Understand the organization's SE readiness and needs

**Activities:**

```
┌──────────────────────────────────────────────────────────────┐
│  STEP 1: SE Maturity Assessment (12 Questions)               │
│  ────────────────────────────────────────────────────────    │
│                                                              │
│  Measures 4 Dimensions:                                      │
│  • Fundamentals (25%)    - SE mindset & knowledge base       │
│  • Organization (30%)    - Roles, processes, training        │
│  • Process Capability (25%) - Requirements, architecture, V&V│
│  • Infrastructure (20%)  - Tools, MBSE adoption              │
│                                                              │
│  Example Question:                                           │
│  "To what extent are SE roles and processes defined?"        │
│    [0] Not available                                         │
│    [1] Ad hoc/undefined                                      │
│    [2] Individually controlled                               │
│    [3] Defined and established                               │
│    [4] Quantitatively predictable                            │
│    [5] Optimized                                             │
│                                                              │
│  Result: Overall Maturity Score (0-5 scale)                  │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  STEP 2: Qualification Archetype Selection                   │
│  ────────────────────────────────────────────────            │
│                                                              │
│  Based on maturity score, system selects training strategy:  │
│                                                              │
│  LOW MATURITY (Score ≤ 1):                                   │
│    → Dual Selection Required:                                │
│      Primary: "SE for Managers" (mandatory)                  │
│      Secondary: Choose based on company goal:                │
│        • "Orientation in Pilot Project"                      │
│        • "Common Basic Understanding"                        │
│        • "Certification"                                     │
│                                                              │
│  HIGH MATURITY (Score > 1):                                  │
│    → Single Selection Based on Scope:                        │
│      Limited scope → "Needs-based Project-oriented Training" │
│      Broad scope   → "Continuous Support"                    │
│                                                              │
│  Supplementary (All Levels):                                 │
│    Large organizations (50+ people) OR Long timelines        │
│    → Add "Train the Trainer"                                 │
└──────────────────────────────────────────────────────────────┘
```

**Key Insight:** Organizations at different maturity levels need fundamentally different training approaches. Low-maturity organizations need management buy-in first; high-maturity organizations need role-specific depth.

### Phase 2: Individual Competency Assessment (All Users)

**Purpose:** Identify each person's competency gaps and generate personalized learning plans

**Activities:**

```
┌──────────────────────────────────────────────────────────────┐
│  STEP 1: Role Identification (2 Options)                     │
│  ────────────────────────────────────────────                │
│                                                              │
│  OPTION A: Role-Based (User knows their role)                │
│    User selects from 14 standard SE roles:                   │
│    • Systems Architect                                       │
│    • Requirements Engineer                                   │
│    • Integration & Test Engineer                             │
│    • Technical Project Manager                               │
│    • ... (11 more roles)                                     │
│                                                              │
│  OPTION B: Task-Based (User describes their work)            │
│    User enters free-text job description:                    │
│    "I define system requirements, coordinate with            │
│     stakeholders, create architecture models, and            │
│     lead design reviews."                                    │
│                                                              │
│    → AI analyzes tasks and identifies relevant SE processes  │
│    → Maps processes to appropriate role(s)                   │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  STEP 2: Competency Self-Assessment (16 Competencies)        │
│  ────────────────────────────────────────────────────────    │
│                                                              │
│  User rates themselves on 16 SE competencies:                │
│                                                              │
│  Core Competencies (4):                                      │
│  1. Systems Thinking                                         │
│  2. System Modeling and Analysis                             │
│  3. Consideration of System Life Cycle Phases                │
│  4. Customer Benefit Orientation                             │
│                                                              │
│  Professional Skills (6):                                    │
│  5. Requirements Management                                  │
│  6. System Architecture Design                               │
│  7. Implementation and Integration                           │
│  8. Verification & Validation                                │
│  9. Interface Management                                     │
│  10. Risk Management                                         │
│                                                              │
│  Social Competencies (3):                                    │
│  11. Communication and Cooperation                           │
│  12. Conflict Management                                     │
│  13. Decision-Making Competence                              │
│                                                              │
│  Management Competencies (3):                                │
│  14. Systems Leadership                                      │
│  15. SE Management                                           │
│  16. Resource and Project Management                         │
│                                                              │
│  Rating Scale (6 levels):                                    │
│  [1] Know   - Aware of concept                               │
│  [2] Understand - Can explain                                │
│  [4] Apply  - Can use in practice                            │
│  [6] Master - Expert, can teach others                       │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  STEP 3: Gap Analysis & Learning Plan Generation             │
│  ────────────────────────────────────────────────            │
│                                                              │
│  System automatically:                                       │
│  1. Compares self-assessment vs. role requirements           │
│  2. Identifies competency gaps                               │
│  3. Prioritizes critical gaps                                │
│  4. Considers organizational archetype                       │
│  5. Generates personalized learning objectives               │
│  6. Recommends specific training modules                     │
│  7. Estimates learning duration                              │
│                                                              │
│  Example Output:                                             │
│  ┌────────────────────────────────────────────┐              │
│  │ Competency: Requirements Management        │              │
│  │ Current Level: 2 (Understand)              │              │
│  │ Required Level: 6 (Master)                 │              │
│  │ Gap: 4 levels                              │              │
│  │ Priority: CRITICAL                         │              │
│  │                                            │              │
│  │ Learning Objectives:                       │              │
│  │ 1. Apply requirements elicitation          │              │
│  │    techniques in project context           │              │
│  │ 2. Create traceable requirements           │              │
│  │    specifications                          │              │
│  │ 3. Lead requirements validation sessions   │              │
│  │                                            │              │
│  │ Recommended Modules:                       │              │
│  │ • M-Anf-G: Requirements basics (8h)        │              │
│  │ • M-Anf-Anw: Requirements application (16h)│              │
│  │                                            │              │
│  │ Estimated Time: 24 hours                   │              │
│  └────────────────────────────────────────────┘              │
└──────────────────────────────────────────────────────────────┘
```

---

## System Architecture Overview

### High-Level System Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                         WEB BROWSER                             │
│                    (User Interface Layer)                       │
└─────────────────────────────────────────────────────────────────┘
                              ↕
            ┌─────────────────────────────────┐
            │      INTERNET / NETWORK         │
            └─────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION SERVER                           │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Frontend (Vue.js) - What Users See                    │     │
│  │  • Login screens                                       │     │
│  │  • Questionnaire forms                                 │     │
│  │  • Results dashboards                                  │     │
│  │  • Learning plan displays                              │     │
│  └────────────────────────────────────────────────────────┘     │
│                              ↕                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Backend (Flask/Python) - Business Logic               │     │
│  │  • User authentication                                 │     │
│  │  • Questionnaire scoring                               │     │
│  │  • Archetype selection algorithm                       │     │
│  │  • Gap analysis calculations                           │     │
│  │  • AI integration for task analysis                    │     │
│  └────────────────────────────────────────────────────────┘     │
│                              ↕                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Database (PostgreSQL) - Data Storage                  │     │
│  │  • Organizations                                       │     │
│  │  • Users (admins and employees)                        │     │
│  │  • Maturity assessments                                │     │
│  │  • Competency assessments                              │     │
│  │  • Learning plans                                      │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components Explained

#### 1. Frontend (User Interface)
- **Technology**: Vue.js web framework
- **Purpose**: What users interact with directly
- **Features**:
  - Responsive forms for questionnaires
  - Interactive dashboards
  - Progress tracking
  - Results visualization

#### 2. Backend (Business Logic)
- **Technology**: Flask (Python web framework)
- **Purpose**: Processes data and enforces business rules
- **Key Functions**:
  - Calculate maturity scores using weighted averages
  - Select archetypes based on decision tree logic
  - Analyze job tasks using AI (OpenAI GPT)
  - Calculate competency gaps
  - Generate learning objectives

#### 3. Database (Data Storage)
- **Technology**: PostgreSQL relational database
- **Purpose**: Persistent storage of all system data
- **Key Tables**:
  - Organizations (company profiles)
  - AdminUser (user accounts)
  - CompetencyAssessment (assessment tracking)
  - UserCompetencySurveyResults (individual scores)
  - RoleCompetencyMatrix (role requirements)

### Multi-Tenancy Design

SE-QPT supports multiple organizations in a single system:

```
Database Structure:

Organization A          Organization B          Organization C
├─ Admin User          ├─ Admin User          ├─ Admin User
├─ 10 Employees        ├─ 5 Employees         ├─ 50 Employees
├─ Maturity: 2.5       ├─ Maturity: 4.1       ├─ Maturity: 1.2
├─ Archetype: Needs-   ├─ Archetype: Cont-    ├─ Archetype: SE for
│  based Training      │  inuous Support      │  Managers + Pilot
└─ 10 Assessments      └─ 5 Assessments       └─ 50 Assessments

Data Isolation: Each organization's data is completely separate
```

---

## Complete User Workflows

### Workflow 1: Administrator Onboarding Journey

```
┌─────────────────────────────────────────────────────────────────┐
│ DAY 1: ADMINISTRATOR REGISTRATION & SETUP                       │
└─────────────────────────────────────────────────────────────────┘

Step 1: Create Account
  ┌──────────────────────────────────────┐
  │ Administrator visits SE-QPT website  │
  │ Clicks "Register as Administrator"   │
  │ Provides:                            │
  │  • Email address                     │
  │  • Password                          │
  │  • Full name                         │
  └──────────────────────────────────────┘
                 ↓
Step 2: Create Organization Profile
  ┌──────────────────────────────────────┐
  │ Administrator enters:                │
  │  • Organization name                 │
  │  • Organization size                 │
  │    [small/medium/large/enterprise]   │
  │                                      │
  │ System generates:                    │
  │  • Unique Organization Code          │
  │    Example: "ABC123"                 │
  └──────────────────────────────────────┘
                 ↓
Step 3: Complete Maturity Assessment
  ┌──────────────────────────────────────┐
  │ Time: 10-15 minutes                  │
  │ Questions: 12 questions              │
  │ Sections:                            │
  │  1. Fundamentals (3 questions)       │
  │  2. Organization (4 questions)       │
  │  3. Process Capability (3 questions) │
  │  4. Infrastructure (2 questions)     │
  │                                      │
  │ Example answers:                     │
  │  MAT_01: SE Mindset? → "Fragmented"  │
  │  MAT_04: SE Roles?   → "Ad hoc"      │
  │  MAT_05: SE Reach?   → "Individual"  │
  └──────────────────────────────────────┘
                 ↓
Step 4: Review Maturity Results
  ┌──────────────────────────────────────┐
  │ System calculates and displays:      │
  │  • Overall Maturity Score: 1.2/5     │
  │  • Maturity Level: "Developing"      │
  │  • Section Breakdown:                │
  │    - Fundamentals: 1.5/5             │
  │    - Organization: 0.8/5 (weak)      │
  │    - Process Capability: 1.3/5       │
  │    - Infrastructure: 1.1/5           │
  └──────────────────────────────────────┘
                 ↓
Step 5: Archetype Selection Questionnaire
  ┌──────────────────────────────────────┐
  │ Based on low maturity (1.2/5):       │
  │ System triggers LOW MATURITY PATH    │
  │                                      │
  │ Question: Primary company goal?      │
  │ Options:                             │
  │  • Apply SE in pilot project         │
  │  • Build basic SE awareness          │
  │  • Develop SE experts                │
  │                                      │
  │ Admin selects: "Build basic SE       │
  │ awareness"                           │
  │                                      │
  │ Additional questions (5 total):      │
  │  • Management readiness              │
  │  • Number of participants            │
  │  • Implementation timeline           │
  └──────────────────────────────────────┘
                 ↓
Step 6: View Selected Archetype
  ┌──────────────────────────────────────┐
  │ DUAL SELECTION RESULT:               │
  │                                      │
  │ Primary Archetype:                   │
  │  "SE for Managers"                   │
  │   → Executive-level SE understanding │
  │   → Change management focus          │
  │                                      │
  │ Secondary Archetype:                 │
  │  "Common Basic Understanding"        │
  │   → Broad organizational awareness   │
  │   → Standardized content             │
  │                                      │
  │ Rationale:                           │
  │  Low SE maturity requires management │
  │  buy-in combined with basic          │
  │  awareness building across teams.    │
  └──────────────────────────────────────┘
                 ↓
Step 7: Receive Organization Code
  ┌──────────────────────────────────────┐
  │ ┌──────────────────────────────────┐ │
  │ │   YOUR ORGANIZATION CODE         │ │
  │ │                                  │ │
  │ │         ABC123                   │ │
  │ │                                  │ │
  │ │  Share this code with your       │ │
  │ │  team members to allow them      │ │
  │ │  to join and complete their      │ │
  │ │  competency assessments.         │ │
  │ └──────────────────────────────────┘ │
  │                                      │
  │ Admin can now:                       │
  │  • Email code to team                │
  │  • Post in team chat                 │
  │  • Include in onboarding materials   │
  └──────────────────────────────────────┘
                 ↓
Step 8: Complete Own Competency Assessment
  ┌──────────────────────────────────────┐
  │ Administrator proceeds to Phase 2    │
  │ to complete their own assessment     │
  │ (see Workflow 2 below)               │
  └──────────────────────────────────────┘
```

### Workflow 2: Employee Onboarding Journey

```
┌─────────────────────────────────────────────────────────────────┐
│ DAY 2+: EMPLOYEE REGISTRATION & ASSESSMENT                      │
└─────────────────────────────────────────────────────────────────┘

Step 1: Employee Registration
  ┌──────────────────────────────────────┐
  │ Employee receives org code from admin│
  │ Visits SE-QPT website                │
  │ Clicks "Register as Employee"        │
  │ Provides:                            │
  │  • Email address                     │
  │  • Password                          │
  │  • Full name                         │
  │  • Organization Code: ABC123         │
  └──────────────────────────────────────┘
                 ↓
Step 2: View Organization Context (Read-Only)
  ┌──────────────────────────────────────┐
  │ Employee sees organization's Phase 1 │
  │ results (cannot modify):             │
  │                                      │
  │ Organization: Acme Engineering       │
  │ Maturity Level: Developing (1.2/5)   │
  │                                      │
  │ Selected Archetypes:                 │
  │  • SE for Managers                   │
  │  • Common Basic Understanding        │
  │                                      │
  │ This context helps employee          │
  │ understand organizational approach   │
  └──────────────────────────────────────┘
                 ↓
Step 3: Role Identification
  ┌──────────────────────────────────────┐
  │ OPTION A: Employee knows their role  │
  │  Selects: "Requirements Engineer"    │
  └──────────────────────────────────────┘
                 OR
  ┌──────────────────────────────────────┐
  │ OPTION B: Employee describes tasks   │
  │  Enters free text:                   │
  │  "I gather requirements from         │
  │   customers, create specifications,  │
  │   validate requirements with team,   │
  │   and manage requirement changes."   │
  │                                      │
  │  AI analyzes and identifies:         │
  │   - Requirements Definition          │
  │   - Stakeholder Needs Management     │
  │   - Requirements Validation          │
  │                                      │
  │  → Maps to: Requirements Engineer    │
  └──────────────────────────────────────┘
                 ↓
Step 4: Competency Self-Assessment
  ┌──────────────────────────────────────┐
  │ Time: 15-20 minutes                  │
  │ Questions: 16 competencies           │
  │                                      │
  │ Example ratings:                     │
  │  1. Systems Thinking: 2 (Understand) │
  │  2. System Modeling: 2 (Understand)  │
  │  5. Requirements Mgmt: 4 (Apply)     │
  │  6. Architecture Design: 1 (Know)    │
  │  11. Communication: 4 (Apply)        │
  │  ... (11 more)                       │
  └──────────────────────────────────────┘
                 ↓
Step 5: Gap Analysis Results
  ┌──────────────────────────────────────┐
  │ System compares:                     │
  │  • Employee's self-ratings           │
  │  • Requirements Engineer role needs  │
  │  • Organizational archetype targets  │
  │                                      │
  │ COMPETENCY GAPS IDENTIFIED:          │
  │                                      │
  │ ┌──────────────────────────────────┐ │
  │ │ Requirements Management          │ │
  │ │ Current: 4 (Apply)               │ │
  │ │ Required: 6 (Master)             │ │
  │ │ Gap: 2 levels                    │ │
  │ │ Priority: HIGH                   │ │
  │ └──────────────────────────────────┘ │
  │                                      │
  │ ┌──────────────────────────────────┐ │
  │ │ System Architecture Design       │ │
  │ │ Current: 1 (Know)                │ │
  │ │ Required: 4 (Apply)              │ │
  │ │ Gap: 3 levels                    │ │
  │ │ Priority: CRITICAL               │ │
  │ └──────────────────────────────────┘ │
  │                                      │
  │ ┌──────────────────────────────────┐ │
  │ │ Systems Thinking                 │ │
  │ │ Current: 2 (Understand)          │ │
  │ │ Required: 4 (Apply)              │ │
  │ │ Gap: 2 levels                    │ │
  │ │ Priority: MEDIUM                 │ │
  │ └──────────────────────────────────┘ │
  └──────────────────────────────────────┘
                 ↓
Step 6: Personalized Learning Plan
  ┌──────────────────────────────────────┐
  │ LEARNING PLAN FOR: John Doe          │
  │ Role: Requirements Engineer          │
  │ Organization Archetype: Basic        │
  │ Understanding + SE for Managers      │
  │                                      │
  │ PRIORITY 1: System Architecture      │
  │  Current: Know (1) → Target: Apply(4)│
  │  Objectives:                         │
  │   • Understand architecture patterns │
  │   • Apply architecture methods       │
  │   • Document architecture decisions  │
  │  Modules:                            │
  │   • M-Arch-G: Architecture basics    │
  │   • M-Arch-App: Architecture apply   │
  │  Duration: 32 hours                  │
  │                                      │
  │ PRIORITY 2: Requirements Management  │
  │  Current: Apply (4) → Target: Mast(6)│
  │  Objectives:                         │
  │   • Lead requirements workshops      │
  │   • Mentor junior engineers          │
  │   • Establish requirements process   │
  │  Modules:                            │
  │   • M-Anf-Adv: Advanced requirements │
  │  Duration: 16 hours                  │
  │                                      │
  │ PRIORITY 3: Systems Thinking         │
  │  Current: Understand (2) → Apply (4) │
  │  Objectives:                         │
  │   • Apply systems thinking to        │
  │     requirements analysis            │
  │   • Identify system boundaries       │
  │   • Analyze interdependencies        │
  │  Modules:                            │
  │   • M-Con: SE Concepts               │
  │  Duration: 8 hours                   │
  │                                      │
  │ TOTAL ESTIMATED TIME: 56 hours       │
  └──────────────────────────────────────┘
                 ↓
Step 7: Track Progress
  ┌──────────────────────────────────────┐
  │ Employee can:                        │
  │  • View their learning plan          │
  │  • Track module completion           │
  │  • Update progress                   │
  │  • Re-assess after training          │
  └──────────────────────────────────────┘
```

### Workflow 3: Administrator Dashboard View

```
┌─────────────────────────────────────────────────────────────────┐
│ ONGOING: ADMINISTRATOR MONITORING                               │
└─────────────────────────────────────────────────────────────────┘

Dashboard Overview:
┌────────────────────────────────────────────────────────────────┐
│ ACME ENGINEERING - ADMINISTRATOR DASHBOARD                     │
│                                                                │
│ Organization Profile:                                          │
│  • Maturity Level: Developing (1.2/5)                          │
│  • Archetype: SE for Managers + Common Basic Understanding     │
│  • Total Employees: 15                                         │
│                                                                │
│ Assessment Progress:                                           │
│  • Completed Assessments: 12/15 (80%)                          │
│  • Pending Assessments: 3                                      │
│  • Average Completion Time: 18 minutes                         │
│                                                                │
│ Team Competency Overview:                                      │
│  ┌──────────────────────────────────────────────────┐          │
│  │ CRITICAL GAPS (Across All Team Members):         │          │
│  │                                                  │          │
│  │ 1. System Architecture Design                    │          │
│  │    Average Current: 1.8/6                        │          │
│  │    Average Required: 4.5/6                       │          │
│  │    Avg Gap: 2.7 levels                           │          │
│  │    Affected: 10/12 employees                     │          │
│  │                                                  │          │
│  │ 2. MBSE and Modeling                             │          │
│  │    Average Current: 1.2/6                        │          │
│  │    Average Required: 4.0/6                       │          │
│  │    Avg Gap: 2.8 levels                           │          │
│  │    Affected: 12/12 employees                     │          │
│  │                                                  │          │
│  │ 3. Systems Thinking                              │          │
│  │    Average Current: 2.3/6                        │          │
│  │    Average Required: 4.2/6                       │          │
│  │    Avg Gap: 1.9 levels                           │          │
│  │    Affected: 11/12 employees                     │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                │
│ Recommended Actions:                                           │
│  1. Schedule team training on System Architecture              │
│  2. Invest in MBSE tool training                               │
│  3. Organize systems thinking workshop                         │
│                                                                │
│ Individual Employee List:                                      │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Name           Role              Status    Gaps  Avg   │    │
│  │ John Doe       Req Engineer      Complete  3    2.5/6  │    │
│  │ Jane Smith     Systems Arch      Complete  2    3.8/6  │    │
│  │ Bob Johnson    Test Engineer     Complete  4    2.1/6  │    │
│  │ Alice Wong     Project Manager   Pending   -    -      │    │
│  │ ... (11 more)                                          │    │
│  └────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────┘
```

---

## Key Features and Capabilities

### 1. Intelligent Archetype Selection

**Feature**: Adaptive training strategy selection based on organizational maturity

**How It Works**:
```
Decision Tree Logic:

Measure MAT_04 (SE Roles & Processes)
    ↓
IF MAT_04 ≤ 1 (Low Maturity):
    PRIMARY: "SE for Managers" (mandatory)
    SECONDARY: Based on ARCH_01 (company goal):
        • "apply_pilot" → "Orientation in Pilot Project"
        • "build_awareness" → "Common Basic Understanding"
        • "develop_experts" → "Certification"

    RESULT: Dual archetype selection

ELSE IF MAT_04 > 1 (Higher Maturity):
    Measure MAT_05 (Rollout Scope)
        ↓
    IF MAT_05 ≤ 1 (Limited scope):
        → "Needs-based Project-oriented Training"
    ELSE IF MAT_05 ≥ 2 (Broad scope):
        → "Continuous Support"

    RESULT: Single archetype selection

SUPPLEMENTARY CHECK (All paths):
    IF (participants ≥ 50) OR (timeline ≥ 12 months):
        ADD: "Train the Trainer"
```

**Why This Matters**:
- Low-maturity organizations need different strategies than mature ones
- Prevents "jumping ahead" to advanced training when basics aren't established
- Ensures executive buy-in for organizations starting SE journey

### 2. AI-Powered Task Analysis

**Feature**: Automatic role identification from free-text job descriptions

**How It Works**:
1. Employee enters natural language description of their tasks
2. AI (OpenAI GPT) analyzes text and identifies relevant ISO 15288 processes
3. System maps processes to role competency requirements
4. Calculates which competencies are needed

**Example**:
```
Input: "I coordinate between customer and development team,
        gather requirements, create specifications, and validate
        that requirements meet customer needs."

AI Analysis:
  Identified Processes:
   • Stakeholder Needs and Requirements Definition
   • System Requirements Definition
   • Requirements Verification
   • Customer Validation

  Mapped Role: Requirements Engineer

  Required Competencies (extracted from processes):
   • Requirements Management: Level 6 (Master)
   • Communication & Cooperation: Level 6 (Master)
   • Systems Thinking: Level 4 (Apply)
   • Customer Benefit Orientation: Level 4 (Apply)
```

**Why This Matters**:
- Not everyone knows their formal "role title"
- People's actual work may not match their job title
- More accurate assessment based on real activities

### 3. Multi-Dimensional Gap Analysis

**Feature**: Comprehensive comparison of current vs. required competencies

**What Gets Analyzed**:
```
For each competency:

1. Role Requirements (from role-competency matrix)
   → What does this role need?

2. Archetype Target (from archetype-competency matrix)
   → What does this training strategy target?

3. Current Self-Assessment (from user input)
   → Where is the employee now?

4. Calculate Target Level:
   Target = MIN(role_requirement, archetype_target)

   Why? Training aligns with both:
   • What the role needs
   • What the organization's strategy supports

5. Calculate Gap:
   Gap = Target - Current

   Positive gap = training needed
   Negative gap = employee exceeds requirements

6. Prioritize:
   CRITICAL: Gap ≥ 3 levels
   HIGH: Gap = 2 levels
   MEDIUM: Gap = 1 level
   LOW: Gap = 0 (already meeting requirements)
```

**Example Calculation**:
```
Competency: Requirements Management

Role Requirement (Requirements Engineer): 6 (Master)
Archetype Target (SE for Managers): 4 (Apply)
Current Self-Assessment: 2 (Understand)

Step 1: Determine target
   Target = MIN(6, 4) = 4 (Apply)

Step 2: Calculate gap
   Gap = 4 - 2 = 2 levels

Step 3: Prioritize
   Gap = 2 → Priority: HIGH

Interpretation:
   Employee needs 2 levels of improvement, from "Understand"
   to "Apply". Even though the role requires "Master" level,
   the organization's archetype only targets "Apply" level,
   so that's the realistic training goal.
```

### 4. Organization-Wide Analytics

**Feature**: Aggregated view of team competency gaps for administrators

**Capabilities**:
- Identify common competency gaps across multiple team members
- Prioritize team training investments
- Track organizational capability growth
- Compare individual vs. organizational averages

**Example Report**:
```
ORGANIZATIONAL COMPETENCY REPORT
Organization: Acme Engineering
Employees Assessed: 12
Date: October 2025

TOP 3 ORGANIZATIONAL GAPS:

1. MBSE and System Modeling
   Average Current Level: 1.2/6 (Know)
   Average Required Level: 4.0/6 (Apply)
   Average Gap: 2.8 levels
   Employees Affected: 12/12 (100%)

   RECOMMENDATION:
   → Invest in MBSE tool training (high impact)
   → All team members need this competency
   → Consider external MBSE consultant

2. System Architecture Design
   Average Current Level: 1.8/6 (Understand)
   Average Required Level: 4.5/6 (Apply)
   Average Gap: 2.7 levels
   Employees Affected: 10/12 (83%)

   RECOMMENDATION:
   → Schedule architecture workshop
   → Pair junior engineers with experienced architects
   → Focus on practical application

3. Systems Thinking
   Average Current Level: 2.3/6 (Understand)
   Average Required Level: 4.2/6 (Apply)
   Average Gap: 1.9 levels
   Employees Affected: 11/12 (92%)

   RECOMMENDATION:
   → Team-wide systems thinking training
   → Integrate into project reviews
   → Use real project examples
```

### 5. Learning Objective Generation

**Feature**: Automatic generation of SMART learning objectives

**SMART Criteria**:
- **S**pecific: Clearly defined outcomes
- **M**easurable: Observable criteria for success
- **A**chievable: Realistic based on current level
- **R**elevant: Connected to role and organizational needs
- **T**ime-bound: Tied to training duration

**Template Structure**:
```
"At the end of [training duration], the participant [action verb]
[competency focus] by [measurable criteria], in order to [purpose/benefit]."
```

**Example Generated Objectives**:
```
Competency: Requirements Management
Current: 2 (Understand) → Target: 4 (Apply)

Generated Learning Objectives:

1. "At the end of the 2-day workshop, the participant applies
   requirements elicitation techniques to gather stakeholder needs
   by conducting structured interviews and documenting at least
   15 requirements, in order to create comprehensive requirement
   specifications for project initiation."

   Measurable: 15+ requirements documented
   Duration: 2 days
   Level: Apply

2. "Within 4 weeks of coaching, the participant validates system
   requirements by facilitating validation sessions with stakeholders
   and documenting validation results for 100% of critical requirements,
   in order to ensure requirements meet actual customer needs."

   Measurable: 100% critical requirements validated
   Duration: 4 weeks
   Level: Apply

3. "After completing the training module, the participant creates
   traceable requirement specifications using requirements management
   tools by linking requirements to design elements and test cases,
   in order to maintain project traceability."

   Measurable: Requirements linked to design & tests
   Duration: Module completion
   Level: Apply
```

---

## Data and Privacy

### What Data Does SE-QPT Collect?

#### Organizational Data
- Organization name
- Organization size category
- Maturity assessment responses (12 questions)
- Archetype selection responses (5-7 questions)
- Selected qualification strategy

#### User Data
- Name and email (for login)
- Role selection or job task descriptions
- Competency self-assessments (16 ratings)
- Learning plan preferences

#### Generated Data
- Maturity scores and levels
- Competency gap analyses
- Learning objectives and plans
- Progress tracking data

### Data Privacy Principles

```
┌─────────────────────────────────────────────────────────────┐
│ 1. MULTI-TENANCY ISOLATION                                  │
│    Each organization's data is completely separated         │
│    No organization can see another's data                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 2. ROLE-BASED ACCESS                                        │
│    Admins: Can view all data in their organization          │
│    Employees: Can only view their own data                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 3. EMPLOYEE TRANSPARENCY                                    │
│    Employees see what organizational context applies to them│
│    No hidden assessments or evaluations                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 4. SECURE STORAGE                                           │
│    All data encrypted in database                           │
│    Passwords hashed (not stored as plain text)              │
│    HTTPS encryption for data transmission                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 5. SELF-ASSESSMENT BASED                                    │
│    Competency ratings are self-reported, not manager-rated  │
│    Focuses on development, not evaluation                   │
└─────────────────────────────────────────────────────────────┘
```

### Who Can See What Data?

```
┌────────────────────────┬─────────┬──────────┬────────────┐
│ Data Type              │  Admin  │ Employee │ Other Orgs │
├────────────────────────┼─────────┼──────────┼────────────┤
│ Org Maturity Score     │   ✓     │   ✓*     │     ✗      │
│ Org Archetype          │   ✓     │   ✓*     │     ✗      │
│ Own Competency Scores  │   ✓     │   ✓      │     ✗      │
│ Own Learning Plan      │   ✓     │   ✓      │     ✗      │
│ Team Member Scores     │   ✓     │   ✗      │     ✗      │
│ Team Aggregates        │   ✓     │   ✗      │     ✗      │
│ Other Org Data         │   ✗     │   ✗      │     ✗      │
└────────────────────────┴─────────┴──────────┴────────────┘

* Employee sees organization's Phase 1 results as READ-ONLY context
```

---

## Validation and Correctness

### How Do We Know SE-QPT is Building the Right Thing?

#### 1. Research-Based Foundation

**SE-QPT integrates validated research from**:

```
┌─────────────────────────────────────────────────────────────┐
│ SOURCE 1: BRETZ Maturity Model                              │
│ • Established SE maturity assessment framework              │
│ • Used in SE-QPT's 12-question maturity assessment          │
│ • Dimensions: Scope and Process maturity                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SOURCE 2: Derik's Competency Assessment Framework           │
│ • 16 SE competencies based on Könemann et al. research      │
│ • Role-competency matrices with empirical validation        │
│ • Task-to-competency mapping methodology                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SOURCE 3: Qualification Archetypes (Marcel's Framework)     │
│ • Evidence-based qualification strategies                   │
│ • Context-appropriate training approaches                   │
│ • Customization level guidance (10% vs 90%)                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ SOURCE 4: ISO/IEC 15288:2023 Standard                       │
│ • International SE process standard                         │
│ • 30 standardized SE processes                              │
│ • Process-to-competency mappings                            │
└─────────────────────────────────────────────────────────────┘
```

#### 2. Algorithm Validation Points

**Key Algorithms to Validate**:

```
ALGORITHM 1: Maturity Score Calculation
┌─────────────────────────────────────────────────────────────┐
│ Input: 12 question responses (0-5 scale)                    │
│ Process:                                                    │
│   1. Calculate section scores (weighted average)            │
│   2. Calculate overall score (weighted average of sections) │
│ Output: Overall maturity 0-5 scale                          │
│                                                             │
│ Validation Questions:                                       │
│  • Do the weights sum to 1.0 for each section?              │
│  • Do the section weights sum to 1.0?                       │
│  • Are scores consistently in 0-5 range?                    │
│  • Do higher inputs produce higher outputs?                 │
└─────────────────────────────────────────────────────────────┘

ALGORITHM 2: Archetype Selection Logic
┌─────────────────────────────────────────────────────────────┐
│ Input: Maturity score + context responses                   │
│ Process: Decision tree with routing variables               │
│ Output: Selected archetype(s)                               │
│                                                             │
│ Validation Questions:                                       │
│  • Are all maturity levels mapped to archetypes?            │
│  • Is dual selection correctly triggered?                   │
│  • Do supplementary archetypes appear when expected?        │
│  • Are maturity thresholds correct (MAT_04 ≤ 1)?            │
└─────────────────────────────────────────────────────────────┘

ALGORITHM 3: Competency Gap Calculation
┌─────────────────────────────────────────────────────────────┐
│ Input: Role, archetype, self-assessment                     │
│ Process:                                                    │
│   1. Get role requirements from matrix                      │
│   2. Get archetype targets from matrix                      │
│   3. Target = MIN(role_req, archetype_target)               │
│   4. Gap = Target - Current                                 │
│   5. Prioritize based on gap size                           │
│ Output: Prioritized competency gaps                         │
│                                                             │
│ Validation Questions:                                       │
│  • Do all 14 roles have competency requirements?            │
│  • Do all archetypes have competency targets?               │
│  • Are priorities correctly assigned?                       │
│  • Are negative gaps handled (already competent)?           │
└─────────────────────────────────────────────────────────────┘
```

#### 3. Test Scenarios for Validation

**Test Case 1: Low Maturity Organization**
```
Input:
  Organization: Small startup
  Maturity responses: All 0-1 (very low)
  Expected maturity: 0.5-1.0 (Initial)

Expected Behavior:
  ✓ Archetype: Dual selection (SE for Managers + Secondary)
  ✓ Secondary: Based on company goal selection
  ✓ Competency targets: Lower (level 2-4, not 6)
  ✓ Focus: Basic awareness, not mastery

Validation:
  • Does system select dual archetype? ✓
  • Are competency targets appropriate? ✓
  • Is learning plan realistic for beginners? ✓
```

**Test Case 2: High Maturity Organization**
```
Input:
  Organization: Established company
  Maturity responses: Mostly 3-4 (high)
  Expected maturity: 3.5-4.5 (Managed/Optimized)

Expected Behavior:
  ✓ Archetype: Single selection (Continuous Support or Needs-based)
  ✓ Based on rollout scope (MAT_05)
  ✓ Competency targets: Higher (level 4-6)
  ✓ Focus: Advanced skills, specialization

Validation:
  • Does system select single archetype? ✓
  • Are competency targets ambitious? ✓
  • Is learning plan advanced? ✓
```

**Test Case 3: Requirements Engineer Role**
```
Input:
  Role: Requirements Engineer
  Self-assessment: Varies (1-4 across competencies)

Expected Behavior:
  ✓ High requirements for:
    - Requirements Management (6 - Master)
    - Communication (6 - Master)
    - Systems Thinking (4 - Apply)
  ✓ Medium requirements for:
    - Architecture (4 - Apply)
    - System Modeling (4 - Apply)
  ✓ Lower requirements for:
    - Implementation (2 - Understand)

Validation:
  • Does role-competency matrix match role? ✓
  • Are critical competencies identified? ✓
  • Are gaps correctly calculated? ✓
```

#### 4. Data Integrity Checks

**Database Consistency**:
```
CHECK 1: Role-Competency Matrix Completeness
  For all 14 roles:
    For all 16 competencies:
      Verify: Role-competency value exists (0, 1, 2, 4, or 6)

CHECK 2: Process-Competency Matrix Completeness
  For all 30 ISO processes:
    For all 16 competencies:
      Verify: Process-competency value exists (0, 1, or 2)

CHECK 3: User-Organization Linking
  For all users:
    Verify: User belongs to exactly one organization
    Verify: User can only access their organization's data

CHECK 4: Assessment Completeness
  For all completed assessments:
    Verify: All required questions answered
    Verify: Scores within valid ranges
    Verify: Timestamps are logical (completed_at > created_at)
```

#### 5. User Acceptance Validation

**Questions for Thesis Advisor Review**:

```
┌─────────────────────────────────────────────────────────────┐
│ PRODUCT VISION VALIDATION                                   │
├─────────────────────────────────────────────────────────────┤
│ 1. Does the two-phase approach make sense?                  │
│    Phase 1: Organization → Phase 2: Individual              │
│                                                             │
│ 2. Is the dual user type (admin/employee) appropriate?      │
│    Or should there be more role differentiation?            │
│                                                             │
│ 3. Does the archetype selection logic align with            │
│    expected organizational behavior?                        │
│    (Low maturity → management buy-in first)                 │
│                                                             │
│ 4. Is the organization code approach for employee           │
│    registration acceptable, or should we use email          │
│    invitations?                                             │
│                                                             │
│ 5. Should employees see organization's maturity results?    │
│    Currently: Yes (read-only transparency)                  │
│                                                             │
│ 6. Are 16 competencies too many for self-assessment?        │
│    Alternative: Reduce to 8-10 core competencies?           │
│                                                             │
│ 7. Is self-assessment appropriate, or should we include     │
│    manager ratings or peer reviews?                         │
│                                                             │
│ 8. Should the system enforce mandatory training             │
│    completion, or just recommend?                           │
│    Currently: Recommend only                                │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary: What You're Building

### SE-QPT in One Paragraph

**SE-QPT is a web-based tool that helps organizations systematically plan Systems Engineering qualification and training programs. It first assesses the organization's SE maturity to select an appropriate qualification strategy, then assesses individual employees' competencies to generate personalized learning plans that align with both their role requirements and the organization's strategic approach.**

### Key Design Decisions

1. **Organization-First**: Assess organizational readiness before individual competencies
2. **Two User Types**: Administrators (strategic planning) and Employees (personal development)
3. **Self-Service Onboarding**: Organization codes enable employee self-registration
4. **Adaptive Strategies**: Different training approaches based on maturity
5. **Multi-Source Integration**: Combines BRETZ, Derik, ISO 15288, and archetype research
6. **Transparent Process**: Employees see organizational context that affects their plans
7. **Self-Assessment Based**: Focus on development, not performance evaluation

### Value Proposition Validation

**For Organizations:**
- Systematic, evidence-based qualification planning
- Strategic alignment of training with organizational maturity
- Resource optimization (right training for right people)
- Team-level competency gap visibility

**For Individuals:**
- Personalized learning paths based on role and current competencies
- Clear competency development roadmap
- Understanding of organizational qualification strategy
- SMART learning objectives

**For SE Community:**
- Demonstrates integration of multiple SE qualification frameworks
- Provides practical application of maturity-based planning
- Validates AI-enhanced competency assessment approach

---

## Questions for Discussion

1. **Scope Validation**: Is the two-phase approach appropriate for your thesis scope?

2. **User Model**: Should there be additional user roles (e.g., training coordinator, HR manager)?

3. **Privacy & Transparency**: Is the current balance of admin visibility vs. employee privacy appropriate?

4. **Assessment Depth**: Are 16 competencies too many? Should we reduce to core 8-10?

5. **Self-Assessment**: Should we add manager or peer ratings, or keep self-assessment only?

6. **Archetype Selection**: Does the low/high maturity dual-path logic make organizational sense?

7. **Employee Onboarding**: Is organization code self-service better than email invitations?

8. **Learning Plan Enforcement**: Should plans be mandatory or recommended?

9. **Organizational Analytics**: What level of team analytics is appropriate for administrators?

10. **Thesis Contribution**: Does this design demonstrate sufficient innovation for master's thesis?

---

## Appendix: Visual Diagrams

### System Context Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     EXTERNAL ACTORS                          │
└─────────────────────────────────────────────────────────────┘

  ┌──────────────┐         ┌──────────────┐
  │ Administrator│         │   Employee   │
  │  (SE Lead)   │         │ (Team Member)│
  └──────┬───────┘         └──────┬───────┘
         │                        │
         │ Completes Phase 1      │ Joins org
         │ Views team results     │ Completes Phase 2
         │                        │ Views own plan
         └────────┬───────────────┘
                  │
                  ↓
     ┌────────────────────────────────┐
     │       SE-QPT SYSTEM            │
     │                                │
     │  • Maturity Assessment         │
     │  • Archetype Selection         │
     │  • Competency Assessment       │
     │  • Gap Analysis                │
     │  • Learning Plan Generation    │
     └────────────┬───────────────────┘
                  │
                  │ Uses for analysis
                  ↓
     ┌────────────────────────────────┐
     │     EXTERNAL SERVICES          │
     │                                │
     │  • OpenAI GPT (task analysis)  │
     │  • PostgreSQL Database         │
     └────────────────────────────────┘
```

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: ORGANIZATIONAL ASSESSMENT                          │
└─────────────────────────────────────────────────────────────┘

Admin → [Maturity Questionnaire] → System
                                     ↓
                        [Calculate Maturity Score]
                                     ↓
                        [Store Maturity Results]
                                     ↓
Admin ← [Display Maturity Level] ← System
                                     ↓
Admin → [Archetype Questionnaire] → System
                                     ↓
                        [Apply Decision Tree Logic]
                                     ↓
                        [Store Selected Archetype]
                                     ↓
Admin ← [Display Archetype + Org Code] ← System

┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: INDIVIDUAL COMPETENCY ASSESSMENT                   │
└─────────────────────────────────────────────────────────────┘

Employee → [Enter Org Code] → System
                                ↓
                   [Validate & Join Organization]
                                ↓
Employee ← [Display Org Context] ← System
                                ↓
Employee → [Select Role OR Describe Tasks] → System
                                              ↓
                                  [If tasks: AI Analysis]
                                              ↓
                                  [Identify Role & Processes]
                                              ↓
                                  [Store Role Mapping]
                                              ↓
Employee ← [Display Role] ← System
                                ↓
Employee → [Competency Self-Assessment] → System
                                           ↓
                              [Compare vs. Role Requirements]
                                           ↓
                              [Compare vs. Archetype Targets]
                                           ↓
                              [Calculate Competency Gaps]
                                           ↓
                              [Generate Learning Objectives]
                                           ↓
                              [Store Assessment Results]
                                           ↓
Employee ← [Display Learning Plan] ← System
```

---

**Document End**

This design summary provides a comprehensive overview of the SE-QPT system from a non-technical perspective, focusing on user workflows, value propositions, and design decisions rather than implementation details.

For technical implementation details, refer to:
- `SE-QPT_Derik_Integration_Analysis.md` - Technical architecture
- `SE-QPT Comprehensive Workflow.md` - Detailed technical workflow
- Database models in `src/competency_assessor/app/models.py`
