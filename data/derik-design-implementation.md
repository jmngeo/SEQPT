# SE Competency Assessment System - Design & Implementation

> **Source:** DerikRoby_MasterThesis_Evaluation_Summary.pdf  
> **Author:** Derik Roby  
> **Topic:** Systems Engineering Competency Assessment Web Application  
> **Relevance to SE-QPT:** Steps 1.3 (Role Mapping) and 2.1 (Competency Assessment)

---

## Table of Contents

1. [Design Overview](#1-design-overview)
2. [System Functional Architecture](#2-system-functional-architecture)
3. [Implementation - Technology Stack](#3-implementation---technology-stack)
4. [Core Functionalities Implementation](#4-core-functionalities-implementation)
5. [Survey Questionnaire Design](#5-survey-questionnaire-design)
6. [Integration Points for SE-QPT](#6-integration-points-for-se-qpt)

---

## 1. Design Overview

### 1.1 Purpose

The SE Competency Assessment System is a web application designed to evaluate Systems Engineering competency levels based on roles and responsibilities within an organization. It addresses limitations identified in previous work (Javaid's thesis) by providing:

- **Multi-role assessments** - Users can be evaluated for multiple roles simultaneously
- **Organizational tailoring** - Customizable competency frameworks for different organizations
- **Validated questionnaires** - Scientifically grounded survey design
- **AI-enhanced mapping** - RAG-based task-to-process mapping for unknown roles

### 1.2 Design Principles

**Key Considerations:**

1. **Scalability** - Accommodate multiple organizations with distinct requirements
2. **Flexibility** - Adapt to evolving organizational structures and needs
3. **Consistency** - Alignment with ISO 15288 standards and INCOSE framework
4. **Usability** - Intuitive interface for both administrators and survey takers
5. **Maintainability** - Modular design for easy configuration
6. **Security** - No collection of personal information
7. **Scientific Validity** - Questionnaires based on Bloom's Taxonomy, Dreyfus Model, and psychometric principles

---

## 2. System Functional Architecture

### 2.1 User Perspective: Performing the Assessment

The system provides three assessment pathways to accommodate different user scenarios:

#### 2.1.1 Role-Based Competency Assessment

**Use Case:** User can map their job role to one of the 14 predefined role clusters

**Process:**
1. User selects one or more roles from predefined clusters
2. System retrieves required competencies from Role-Competency Matrix
3. User completes competency survey
4. System compares recorded vs. required competencies
5. Gap analysis and feedback provided

**Multiple Role Support:**
- For users with multiple roles, system selects maximum required level across all selected roles for each competency
- Algorithm: `Required_Level = max(Role_Competency[role1], Role_Competency[role2], ...)`

#### 2.1.2 Task-Based Competency Assessment

**Use Case:** User cannot identify with predefined role clusters

**Process:**
1. User inputs job tasks and responsibilities in natural language
2. Categorizes tasks by involvement level:
   - **Supporting** - Assists in the process
   - **Responsible** - Directly executes or leads
   - **Designing** - Defines or improves workflows
3. **RAG mechanism** maps tasks to ISO 15288 processes
4. System derives competency requirements from identified processes
5. User completes survey and receives tailored assessment

**Key Innovation:** Intelligent task-to-process mapping using Retrieval-Augmented Generation (RAG) with LangChain

#### 2.1.3 Full Comprehensive Competency Assessment

**Use Case:** User seeks complete competency evaluation without role constraints

**Process:**
1. User assessed across all 16 competencies
2. System analyzes competency profile
3. **Role recommendation** - System suggests best-fit roles based on demonstrated competencies
4. Uses distance metrics (Euclidean or Manhattan) for role matching

**Distance Metrics:**
- **Euclidean Distance** - For roles requiring balanced proficiency across competencies
- **Manhattan Distance** - For specialist roles with strong focus on specific competencies

---

### 2.2 Admin Perspective: Preparation for Assessment

![Admin Perspective](Figure 5-2: Functional Overview from Admin Perspective)

#### 2.2.1 Data Models to Configure

**Core Data Models:**

1. **ISO Processes** - 30 standardized processes from ISO 15288
   - Static, view-only for transparency
   - Foundation for process-competency mapping

2. **Competencies** - 16 SE competencies adapted from INCOSE
   - Categories: Core (4), Professional (6), Social/Personal (3), Management (3)
   - Static, based on Könemann et al. framework

3. **Role Clusters** - 14 predefined role clusters
   - View-only in current design
   - Mapped to processes with involvement levels

4. **Role-Process Matrix**
   - Maps roles to ISO processes with involvement levels:
     - 0 = Not Relevant
     - 1 = Supporting
     - 2 = Responsible
     - 3 = Designing
   - **Organization-specific** - Each organization can customize
   - Default values from Könemann et al.

5. **Process-Competency Matrix**
   - Maps competencies to processes with proficiency requirements:
     - 0 = Not Useful
     - 1 = Useful
     - 2 = Necessary
   - **Static across organizations** - Same for all

6. **Role-Competency Matrix** *(Derived)*
   - Automatically calculated: `Role-Competency = Role-Process × Process-Competency`
   - Formula: `Role_Competency[r][c] = max(Role_Process[r][p] × Process_Competency[p][c])`
   - Competency levels: 0, 1 (Know), 2 (Understand), 3-4 (Apply), 6 (Master)
   - **Auto-recalculation** triggered when source matrices modified

7. **Organizational Configuration**
   - Supports multiple organizations with unique competency requirements
   - Each organization gets dedicated Role-Process Matrix
   - Corresponding Role-Competency Matrix generated automatically

#### 2.2.2 Automatic Recalculation Mechanism

**Trigger Conditions:**
- Process-Competency Matrix updated → System-wide recalculation
- Role-Process Matrix modified → Organization-specific recalculation only
- New organization added → Generate matrices with default values

**Backend Implementation:**
1. Admin modifies matrix via Vue UI
2. Frontend triggers API call to Flask backend
3. Backend invokes PostgreSQL stored procedure
4. Stored procedure updates Role-Competency Matrix
5. Changes reflected in database immediately

---

### 2.3 Complete Survey Workflow

![Survey Workflow](Figure 5-3: Workflow of SE Competency Assessment Survey)

**Workflow Steps:**

1. **Organization Selection**
   - Individual or organization-affiliated?
   - Organization key determines which Role-Competency Matrix to use

2. **Assessment Path Selection**
   - Role-based assessment → Select roles
   - Full assessment → Complete all competencies
   - Task-based (if roles don't fit) → Describe tasks

3. **Survey Execution**
   - 16 questions, one per competency
   - Hierarchical response groups based on Bloom's Taxonomy

4. **Required Competency Calculation**
   - Different algorithm for each path
   - Considers organizational context

5. **Results & Feedback**
   - Radar chart visualization
   - LLM-generated personalized feedback
   - Gap analysis with actionable recommendations
   - PDF export capability

---

## 3. Implementation - Technology Stack

### 3.1 Frontend Framework

**Vue.js 3** selected for:
- Gentle learning curve compared to React/Angular
- Component-based architecture for modularity
- Reactive data binding
- Virtual DOM for performance
- Progressive framework design
- Comprehensive documentation

**State Management: Pinia**
- Stores user details and survey responses before submission
- Enables navigation, review, and modifications
- Official state management library for Vue 3

**Visualization: Vue-charts**
- Radar chart implementation for competency visualization
- Interactive filtering by competency area

**PDF Export: jsPDF**
- Export results for future reference
- Structured competency reports

### 3.2 Backend Framework

**Flask (Python-based)** chosen for:
- Lightweight and adaptable
- Rapid development capability
- Minimalist design - focus on core functionality
- Modular architecture for iterative enhancements
- Large open-source community
- Seamless integration with Python-based LLM frameworks
- Ideal for agile development process

### 3.3 LLM Development Framework

**LangChain** selected for:

1. **Structured Output Capabilities**
   - JSON-formatted responses essential for frontend-backend communication
   - Enables seamless API integration

2. **Community Support**
   - 100K+ GitHub stars
   - Continuous improvements and extensive documentation

3. **Python-Based**
   - Uniform tech stack with Flask backend
   - Facilitates integration and pipeline development

4. **Advanced Chaining Mechanisms**
   - Multi-step LLM operations (preprocessing, retrieval, generation)
   - Orchestrates complex workflows efficiently

**AI Models Used:**
- **GPT-4o mini** - Chat model for reasoning and generation
- **text-embedding-ada-002** - Embedding model for semantic similarity

### 3.4 Database

**PostgreSQL** chosen for:
- Prior experience with the technology
- Widely used, free, open-source
- Object-relational database with advanced capabilities
- Extensive community support
- Seamless Docker integration
- Available as official Docker image for containerization

**Database Schema:**
- Stores all matrices (Role-Process, Process-Competency, Role-Competency)
- Organization-specific mappings with organization keys
- Survey results with organizational context
- Supports stored procedures for automatic recalculation

### 3.5 Deployment Infrastructure

**Virtual Machine (VM) Environment:**
- Controlled and isolated infrastructure
- Dedicated resources for performance, security, reliability

**Containerization with Docker:**
- Flask backend
- Vue.js frontend
- PostgreSQL database
- Each component in separate container

**Docker Compose:**
- Manages and coordinates multi-container application
- Enables seamless orchestration

**Benefits:**
- Consistency across environments
- Simplified deployment
- Modularity and ease of maintenance
- Follows modern DevOps practices

---

## 4. Core Functionalities Implementation

### 4.1 Administrative Management Module

#### 4.1.1 Matrix Configuration Interface

Admins can:
- **View** ISO Processes and Competencies (static)
- **View** Role Clusters (static)
- **Update** Role-Process Matrix (organization-specific)
- **Update** Process-Competency Matrix (system-wide)
- **Add** new organizations with default matrices

#### 4.1.2 Organization Management

**Adding New Organization:**
1. Admin creates organization with unique key
2. System generates Role-Process Matrix with default values
3. System auto-calculates Role-Competency Matrix
4. Admin can customize Role-Process Matrix collaboratively
5. Any changes trigger automatic recalculation

---

### 4.2 Survey Module Implementation

#### 4.2.1 Organizational Tailoring

**User Selection:**
- Individual → Uses default Role-Competency Matrix
- Organization member → Requires organization key

**Backend Processing:**
- Organization key filters appropriate matrices from database
- Ensures competency requirements align with organizational context
- Scalable for multiple organizations

![Organizational Tailoring](Figure 6-3: Organizational Tailoring User Perspective)

#### 4.2.2 Multiple Role Assessment

**Algorithm 1: Required Competency Calculation**

```
Input: Selected roles, Organization Key

Step 1: Retrieve role-competency mappings for selected roles
        (filtered by organization or individual context)

Step 2: For each competency, select MAXIMUM required level 
        across all selected roles

Output: Required competency levels for performing selected roles
```

**Example:**
- Role 1 requires: Systems Thinking = 4, Requirements = 6
- Role 2 requires: Systems Thinking = 6, Requirements = 3
- **Result:** Systems Thinking = 6, Requirements = 6

![Multiple Role Assessment](Figure 6-4: Workflow for Multiple-Role Assessment)

#### 4.2.3 Task-Based Assessment for Unknown Roles

**Algorithm 2: Task-Based Required Competency Calculation**

```
Input: User tasks in natural language (Supporting, Responsible, Designing)

Step 1: Map tasks to ISO processes using RAG mechanism

Step 2: Store mapped data as entry in Role-Process Matrix for unknown role

Step 3: Compute Role-Competency Matrix:
        - Multiply new Role-Process entry × Process-Competency Matrix
        - Select maximum level for each competency

Output: Required competency levels for described tasks
```

**Key Innovation: RAG Pipeline Implementation**

---

### 4.3 RAG Pipeline for Task-to-ISO Process Mapping

![RAG Process Model](Figure 1: DSRM Process for MBA Technique Study)

#### 4.3.1 Step 1: Knowledge Base Preparation

![Knowledge Base Prep](Figure 6-6: Preprocessing and Vector Storage for RAG)

**Process:**

1. **Manual Extraction** from ISO/IEC/IEEE 15288:2023
   - Extract 30 ISO processes
   - Include descriptions, activities, and tasks
   - One-time preprocessing task

2. **Chunking Strategy**
   - Each chunk = one ISO process with all related content
   - No overlap or information leakage
   - Process-level segmentation for precise matching

3. **Vectorization**
   - Convert text to embeddings using OpenAI's text-embedding-ada-002
   - High-dimensional numerical representations capture semantic meaning
   - Enables similarity-based retrieval

4. **Storage in Vector Database**
   - **FAISS (Facebook AI Similarity Search)** library
   - Local storage (no external database needed)
   - Optimized for fast similarity searches
   - Lightweight yet efficient approach

**Why FAISS?**
- Sufficient for current scope
- Fast retrieval without external database overhead
- Efficient handling of vectorized data

#### 4.3.2 Step 2: User Input Pre-Processing

![Input Preprocessing](Figure 6-7: Pre-processing Pipeline for User Task Inputs)

**Three-Stage LLM Workflow:**

**Stage 1: Language Detection**
- LLM determines if input is in English
- Non-English inputs flagged for translation
- Ensures consistent language for semantic matching

**Stage 2: Translation (if needed)**
- Separate LLM prompt for translation
- **Temperature = 0** for accurate, one-to-one translation
- No creative variations
- Improves retrieval accuracy in FAISS vector store

**Stage 3: Validation**
- LLM checks if tasks are meaningful and SE-relevant
- Filters out irrelevant or nonsensical entries
- Notifies user if inputs invalid
- Prompts for refinement if necessary

**Why Pre-Processing?**
- Standardizes user input format
- Improves retrieval accuracy
- Aligns responses with competency framework
- Reduces noise in RAG pipeline

#### 4.3.3 Step 3: Pre-RAG Reasoning (Enhancement)

![Pre-RAG Reasoning](Figure 6-8: Pre-RAG Reasoning Step)

**Why This Step?**
- Initial experiments with direct RAG showed poor performance
- Basic RAG struggled to classify tasks effectively
- Low success rates for matching user tasks to ISO processes

**Enhanced Approach:**

1. **Creative LLM Reasoning First**
   - Provide LLM with all 30 ISO process names and short definitions
   - High temperature for creative reasoning
   - Ask LLM to deduce which tasks user is performing
   - Include biases to weight certain ISO processes

2. **Structured Output**
   - LLM outputs identified ISO processes as JSON
   - Used as intermediate step before retrieval

3. **Extract Descriptions**
   - Retrieved ISO process descriptions from database
   - Prepared for vector search in next step

**Benefits:**
- Reduced token usage by narrowing search space
- Improved retrieval accuracy
- Contextually aligned queries with user input
- Significant performance improvement

#### 4.3.4 Step 4: Final RAG - ISO Process Retrieval and Classification

![Final RAG Step](Figure 6-9: ISO Process Retrieval and User Task Classification)

**Process:**

1. **Vector Retrieval**
   - Use identified processes from Step 3
   - Retrieve k+4 documents from FAISS vector store
   - k = number of processes from pre-reasoning
   - +4 buffer to capture potentially related processes
   - Ensures no relevant processes missed

2. **Augmented Prompt Construction**
   - Combine retrieved ISO process chunks
   - Add validated user tasks
   - Create comprehensive context for LLM

3. **Final LLM Classification**
   - Query LLM with augmented prompt
   - LLM categorizes user involvement:
     - **Responsible for** - Directly executes or leads
     - **Supporting** - Assists in process
     - **Designing** - Defines or improves workflows
   - Returns three separate lists of ISO processes

4. **Structured Output**
   - JSON format with three categories
   - Clear mapping of tasks to processes
   - Ready for competency calculation

**Result:**
- Accurate task-to-process mapping
- Input for Algorithm 2 (Task-Based Required Competency Calculation)
- Enables competency assessment for unknown roles

**RAG Pipeline Performance:**
Evaluated using RAGAS framework (Retrieval-Augmented Generation Assessment) - See Evaluation section

---

#### 4.2.4 Full Comprehensive Assessment

![Full Assessment](Figure 6-10: Full Comprehensive Assessment Workflow)

**Purpose:** Role discovery based on competency profile

**Process:**

1. **Organization Context Selection**
   - Individual or organization member?
   - Determines which Role-Competency Matrix to use

2. **Complete Survey**
   - User assessed on all 16 competencies
   - No predefined role requirements

3. **Role Matching Algorithm**
   - Compare user's competency profile with all roles
   - Calculate distance between user profile and each role
   - Select role(s) with minimum distance

**Distance Metrics:**

- **Euclidean Distance:**
  ```
  d = sqrt(Σ(user_level - role_level)²)
  ```
  - Penalizes significant variations
  - Best for roles requiring balanced proficiency

- **Manhattan Distance:**
  ```
  d = Σ|user_level - role_level|
  ```
  - Treats each competency separately
  - Best for specialist roles
  - Allows strong specialization

**System Flexibility:**
- Administrators can switch between metrics
- Tailored to organizational requirements

4. **Role Recommendations**
   - Best-fit roles identified
   - Sent to Results & Feedback Module
   - Competency gap analysis relative to recommended roles
   - Data-driven career guidance

---

### 4.4 Survey Assessment Implementation

#### 4.4.1 Questionnaire Design Based on Könemann et al.

**Competency Levels Mapped:**

| Matrix Value | Competency Level | Description |
|--------------|------------------|-------------|
| 0 | Not Needed | Competency not required |
| 1 | Knowing | Basic awareness of concepts |
| 2 | Understanding | Grasp and explain fundamentals |
| 3-4 | Applying | Active use in work tasks |
| 6 | Mastering | Expert-level, guide others |

**Question Design:**

![Questionnaire Example](Figure 6-11: Systems Thinking Competency Questionnaire)

- **Definition-based** - Uses Könemann et al. definitions
- **Second-person perspective** - "You can..." instead of "The role requires..."
- **Self-assessment format** - Enables users to evaluate themselves
- **One question per competency** - 16 questions total

**Response Structure - Hierarchical Groups:**

- **Group 1** → Level 1 (Knowing)
- **Group 2** → Level 2 (Understanding)
- **Group 3** → Level 3-4 (Applying)
- **Group 4** → Level 6 (Mastering)
- **Group 5** → Level 0 (Not Relevant)

**Submission Logic:**
- Highest selected group determines competency level
- System stores maximum group level per competency
- Forwarded to Results & Feedback Module

---

### 4.5 Results and Feedback Module

#### 4.5.1 Data Aggregation

**Structured Dataset Created:**

```json
{
  "competency_area": "Core / Professional / Social / Management",
  "competency_name": "Systems Thinking / Requirements Mgmt / etc.",
  "user_recorded_level": 1-6,
  "user_recorded_indicator": "Description of user's level",
  "required_level": 1-6,
  "required_indicator": "Description of required level"
}
```

**Storage:**
- Results table in PostgreSQL
- Organization key included if applicable
- Enables individual and organizational analysis

#### 4.5.2 Radar Chart Visualization

![Radar Chart](Figure 6-13: Radar Chart Visualization)

**Implementation:**
- **Vue-charts** package for rendering
- Two-color comparison:
  - One color: User recorded competencies
  - Another color: Required competencies
- **Interactive features:**
  - Dynamic filtering by competency area
  - Focus on specific skills
  - Clear gap visualization

**Chart Elements:**
- 16 axes (one per competency)
- Scale: 0-6 competency levels
- Overlap shows alignment
- Gaps show areas needing improvement

#### 4.5.3 LLM-Generated Personalized Feedback

**Prompt Structure:**

```
You are a helpful assistant specializing in SE Competency Assessments.

User Details:
{
  "competency_area": Category,
  "competency_name": Specific competency,
  "user_level": Recorded level,
  "user_indicator": Description of user's level,
  "required_level": Expected level,
  "required_indicator": Description of required level
}

Feedback Requirements:
1. Summarize user's strengths (meeting/exceeding expectations)
2. Identify gaps (current level vs. required level)
3. Offer specific, actionable improvement suggestions
4. Use supportive, growth-encouraging tone
5. Emphasize practical methods: training, practice, mentorship, resources
6. Use neutral terms ("recorded level", "required level") not explicit levels
```

**Process:**
1. Run for all 16 competencies
2. Generate comprehensive feedback report
3. Display alongside radar chart
4. Provide clear understanding of strengths and improvement areas

**Export Capability:**
- PDF generation using jsPDF
- Structured record for future reference
- Professional development planning tool

#### 4.5.4 Organizational Analysis

**Admin Capabilities:**
- Access individual user scores
- Conduct aggregated analyses
- Evaluate overall organizational competency standing
- Identify collective skill gaps
- Develop targeted training programs
- Align workforce competencies with strategic objectives

---

## 5. Survey Questionnaire Design

### 5.1 Scientific Foundation

#### 5.1.1 Bloom's Taxonomy Integration

**Hierarchical Competency Classification:**

1. **Not Relevant** (0) - Does not apply
2. **Knowing** (1) - Remember, recognize
3. **Understanding** (2) - Comprehend, explain
4. **Applying** (3-4) - Execute, implement
5. **Mastering** (6) - Evaluate, create, lead

**Benefits:**
- Clear differentiation between levels
- Progressive skill development
- Standardized evaluation framework

#### 5.1.2 Dreyfus Model of Skill Acquisition

**Five Stages Applied:**

1. **Novice** → Knowing
2. **Advanced Beginner** → Understanding
3. **Competent** → Applying
4. **Proficient** → Advanced Applying
5. **Expert** → Mastering

**Integration:**
- Ensures logical progression
- Structured competency level advancement
- Clear skill acquisition pathway

### 5.2 Psychometric Principles

#### 5.2.1 Item Response Theory (IRT)

**Application:**
- Questions structured in increasing difficulty
- Selecting higher level implies proficiency in lower levels
- Hierarchical response validation

**Example:**
- If user selects "Applying" → Implies "Knowing" and "Understanding" achieved
- Progressive skill demonstration

#### 5.2.2 Guttman Scaling

**Implementation:**
- Hierarchical structure ensures logical progression
- Predefined competency groups (1-5)
- Not traditional Likert scale, but follows Guttman principles

**Benefits:**
- Structured competency progression
- Clear skill level differentiation
- Reliable self-assessment mechanism

#### 5.2.3 Bias Minimization

**Considerations from Choi and Pak (2005):**
- Social desirability bias - Neutral wording
- Acquiescence bias - Balanced question framing
- Extreme responding - Mid-point options available
- Response sets - Varied question structures

### 5.3 Cognitive UX Considerations

#### 5.3.1 Hick's Law

**Application:**
- Limit response choices to minimize cognitive overload
- 5 response groups (including "Not Relevant")
- Reduces decision fatigue

**Result:**
- Faster completion times
- More accurate self-assessment
- Better user experience

#### 5.3.2 Dual-Process Theory (Kahneman)

**Balance:**
- **System 1 (Fast/Intuitive)** - For familiar competencies
- **System 2 (Slow/Analytical)** - For complex competencies

**Design Impact:**
- Quick selections for known areas
- Deeper thinking for uncertain competencies
- Natural cognitive flow

### 5.4 Validation

**Alignment Check:**
- Competency definitions match INCOSE standards
- Cross-validated with Könemann et al. framework
- Statistical evaluation performed
- Expert review conducted

**Results:**
- High correlation with expected outcomes
- Reliable competency measurement
- Scientifically grounded assessment

---

## 6. Integration Points for SE-QPT

### 6.1 How This Fits in Your SE-QPT Prototype

#### 6.1.1 Step 1.3: Role Mapping

**Derik's Contribution:**
- **Three pathways** to map roles → competencies
- **Role-based**: Direct selection from 14 clusters
- **Task-based**: RAG-powered mapping for unknown roles
- **Full assessment**: AI-recommended roles based on profile

**Your Integration:**
```python
# Use Derik's role mapper in Step 1.3
role_mapping_result = derik_role_mapper.assess_user(
    input_type='task-based',  # or 'role-based', 'full'
    user_data=company_employee_data
)

# Returns:
# - Mapped role cluster(s)
# - Required competency levels per role
# - Confidence scores
```

#### 6.1.2 Step 2.1: Competency Assessment

**Derik's Contribution:**
- **Validated questionnaire** with 16 questions
- **Organizational tailoring** support
- **Gap analysis** (recorded vs. required)
- **AI-generated feedback**

**Your Integration:**
```python
# Use Derik's competency assessor in Step 2.1
competency_gaps = derik_competency_assessor.assess(
    user=employee,
    organization=company_context,
    role_requirements=role_mapping_result
)

# Returns:
# - Competency gap analysis
# - Current vs. required levels
# - Personalized feedback
# - Training recommendations
```

#### 6.1.3 Data Flow in SE-QPT

```
SE-QPT Step 1.3 (Role Mapping)
    ↓
[Use Derik's Role Mapper]
    - Input: Employee role/tasks
    - Output: Role cluster(s), Required competencies
    ↓
SE-QPT Step 2.1 (Competency Assessment)
    ↓
[Use Derik's Competency Assessor]
    - Input: Role requirements, Employee self-assessment
    - Output: Competency gaps
    ↓
SE-QPT Step 2.2 (Learning Objectives)
    ↓
[Your RAG LLM generates company-specific objectives]
    - Input: Competency gaps, Company PMT data
    - Output: Customized learning objectives
```

### 6.2 Technical Integration Requirements

#### 6.2.1 API Endpoints Needed

**From Derik's System:**

```python
# Role Mapping Endpoints
POST /api/role-mapper/role-based
POST /api/role-mapper/task-based  # Uses RAG
POST /api/role-mapper/full-assessment

# Competency Assessment Endpoints
POST /api/competency/assess
GET /api/competency/gaps/{user_id}
GET /api/competency/feedback/{user_id}

# Matrix Management (Admin)
GET /api/matrix/role-process/{org_id}
PUT /api/matrix/role-process/{org_id}
GET /api/matrix/role-competency/{org_id}
```

#### 6.2.2 Data Models to Share

**Role-Competency Matrix:**
```json
{
  "organization_id": "org_123",
  "role_id": "systems_architect",
  "competencies": {
    "systems_thinking": 6,
    "requirements_mgmt": 4,
    "architecture_design": 6,
    ...
  }
}
```

**Competency Gap Result:**
```json
{
  "user_id": "emp_456",
  "assessment_date": "2025-09-30",
  "gaps": [
    {
      "competency": "systems_thinking",
      "current_level": 2,
      "required_level": 4,
      "gap": 2,
      "priority": "high"
    },
    ...
  ]
}
```

#### 6.2.3 RAG Pipeline Integration

**For Task-Based Assessment:**

```python
# Your SE-QPT can call Derik's RAG pipeline
iso_processes = derik_rag_pipeline.map_tasks_to_processes(
    user_tasks={
        'responsible': ["Define system requirements", "Coordinate with stakeholders"],
        'supporting': ["Review architecture documents"],
        'designing': ["Develop requirements elicitation process"]
    },
    language='en'  # Auto-detected and translated if needed
)

# Returns:
# {
#   'responsible': ['Requirements Definition', 'Stakeholder Needs and Requirements'],
#   'supporting': ['Architecture Definition'],
#   'designing': ['Requirements Management']
# }
```

### 6.3 Deployment Considerations

**Derik's System Architecture:**
- Frontend: Vue.js 3 + Pinia
- Backend: Flask + LangChain
- Database: PostgreSQL
- Deployment: Docker containers via Docker Compose
- AI: OpenAI GPT-4o mini + text-embedding-ada-002

**Your SE-QPT Integration Options:**

**Option 1: Microservices**
- Deploy Derik's system as separate service
- API-based communication
- Independent scaling

**Option 2: Monolithic Integration**
- Incorporate Derik's modules into your codebase
- Shared database
- Unified deployment

**Option 3: Hybrid**
- Use Derik's role mapper and competency assessor as libraries
- Implement your own UI on top
- Share PostgreSQL database

---

## 7. Key Takeaways for SE-QPT Development

### 7.1 What to Adopt

✅ **Role-Process-Competency Matrix Structure**
- Proven, validated framework
- Automatic recalculation mechanism
- Organizational customization support

✅ **Task-Based Assessment via RAG**
- Handles unknown/new roles effectively
- 4-step pipeline: Prep → Preprocess → Pre-Reason → Retrieve
- Validated with RAGAS framework

✅ **Questionnaire Design**
- Scientifically grounded (Bloom, Dreyfus, IRT, Guttman)
- 16 questions, one per competency
- Cognitive UX principles applied

✅ **Results Visualization**
- Radar charts for gap analysis
- LLM-generated personalized feedback
- PDF export for documentation

### 7.2 What to Customize for SE-QPT

🔧 **Learning Objectives Generation (Step 2.2)**
- Derik provides competency gaps
- Your RAG LLM generates company-specific objectives
- Use company PMT data for customization

🔧 **Module Selection (Step 3.2)**
- Use gap analysis from Derik's system
- Your system selects appropriate modules
- Match to qualification archetypes

🔧 **Learning Format Selection (Step 3.4)**
- Integrate Sachin's learning format research
- Use Derik's competency profile as input
- Select formats based on company context

### 7.3 Implementation Roadmap

**Phase 1: Foundation** (Weeks 1-2)
- Set up Role-Process-Competency matrices
- Implement automatic recalculation
- Create basic questionnaire interface

**Phase 2: Role Mapping** (Weeks 3-4)
- Implement role-based assessment
- Build task-based RAG pipeline
- Add full assessment with role recommendations

**Phase 3: Assessment & Results** (Weeks 5-6)
- Deploy survey module
- Implement radar chart visualization
- Add LLM feedback generation

**Phase 4: Integration** (Weeks 7-8)
- Connect to your SE-QPT workflow
- Integrate RAG for learning objectives
- Link to module selection

**Phase 5: Testing & Refinement** (Weeks 9-10)
- Validate with test users
- Evaluate RAG pipeline accuracy
- Refine based on feedback

---

## 8. References & Resources

### 8.1 Key Papers & Frameworks

- **Könemann et al. [KWA+22]** - Stakeholder-specific SE competency framework
- **ISO/IEC 15288:2023** - Systems and software engineering lifecycle processes
- **INCOSE SECF [sec23]** - Systems Engineering Competency Framework
- **Bloom's Taxonomy [Blo56]** - Educational objectives classification
- **Dreyfus Model [DD80]** - Skill acquisition model

### 8.2 Technologies & Tools

- **LangChain** - LLM application development framework
- **FAISS** - Facebook AI Similarity Search for vector operations
- **OpenAI API** - GPT-4o mini, text-embedding-ada-002
- **RAGAS** - RAG evaluation framework
- **Vue.js 3 + Pinia** - Frontend framework and state management
- **Flask** - Python web framework
- **PostgreSQL** - Relational database
- **Docker + Docker Compose** - Containerization and orchestration

### 8.3 Evaluation Methods

- **RAGAS Metrics** - For RAG pipeline accuracy
- **Usability Testing** - User experience evaluation
- **Statistical Validation** - ANOVA for LLM rating correlation
- **Requirement Coverage Matrix** - Functional validation

---

## Appendix A: Algorithms

### Algorithm 1: Required Competency Calculation (Multiple Roles)

```python
def calculate_required_competencies(selected_roles, organization_key):
    """
    Calculate required competency levels for multiple roles.
    
    Args:
        selected_roles: List of role IDs
        organization_key: Organization identifier (or 'default' for individuals)
    
    Returns:
        Dictionary of competency: required_level pairs
    """
    # Step 1: Retrieve role-competency mappings
    role_competency_matrix = get_role_competency_matrix(organization_key)
    
    required_competencies = {}
    
    # Step 2: For each competency, select maximum level across all roles
    for competency in ALL_COMPETENCIES:
        max_level = 0
        for role in selected_roles:
            level = role_competency_matrix[role][competency]
            max_level = max(max_level, level)
        
        required_competencies[competency] = max_level
    
    return required_competencies
```

### Algorithm 2: Task-Based Required Competency Calculation

```python
def calculate_task_based_competencies(user_tasks, organization_key):
    """
    Calculate required competencies based on user-described tasks.
    
    Args:
        user_tasks: Dict with 'responsible', 'supporting', 'designing' task lists
        organization_key: Organization identifier
    
    Returns:
        Dictionary of competency: required_level pairs
    """
    # Step 1: Map tasks to ISO processes using RAG
    iso_processes = rag_pipeline.map_tasks_to_processes(user_tasks)
    
    # Step 2: Create role-process entry for unknown role
    role_process_entry = create_role_process_entry(iso_processes)
    
    # Step 3: Compute role-competency values
    process_competency_matrix = get_process_competency_matrix()
    
    required_competencies = {}
    for competency in ALL_COMPETENCIES:
        max_level = 0
        for process, involvement_level in role_process_entry.items():
            process_competency_level = process_competency_matrix[process][competency]
            combined_level = involvement_level * process_competency_level
            max_level = max(max_level, combined_level)
        
        required_competencies[competency] = max_level
    
    return required_competencies
```

### Algorithm 3: Role Recommendation (Full Assessment)

```python
def recommend_roles(user_competency_profile, organization_key, distance_metric='euclidean'):
    """
    Recommend best-fit roles based on competency profile.
    
    Args:
        user_competency_profile: Dict of competency: user_level pairs
        organization_key: Organization identifier
        distance_metric: 'euclidean' or 'manhattan'
    
    Returns:
        List of (role, distance_score, match_percentage) tuples
    """
    role_competency_matrix = get_role_competency_matrix(organization_key)
    
    role_distances = []
    
    for role in ALL_ROLES:
        if distance_metric == 'euclidean':
            distance = calculate_euclidean_distance(
                user_competency_profile,
                role_competency_matrix[role]
            )
        else:  # manhattan
            distance = calculate_manhattan_distance(
                user_competency_profile,
                role_competency_matrix[role]
            )
        
        match_percentage = calculate_match_percentage(distance)
        role_distances.append((role, distance, match_percentage))
    
    # Sort by distance (lower is better)
    role_distances.sort(key=lambda x: x[1])
    
    return role_distances
```

---

## Appendix B: Database Schema

### Core Tables

```sql
-- ISO Processes (Static)
CREATE TABLE iso_processes (
    process_id VARCHAR(50) PRIMARY KEY,
    process_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50)
);

-- Competencies (Static)
CREATE TABLE competencies (
    competency_id VARCHAR(50) PRIMARY KEY,
    competency_name VARCHAR(255) NOT NULL,
    category VARCHAR(50),  -- Core, Professional, Social/Personal, Management
    definition TEXT
);

-- Role Clusters (Static)
CREATE TABLE role_clusters (
    role_id VARCHAR(50) PRIMARY KEY,
    role_name VARCHAR(255) NOT NULL,
    description TEXT
);

-- Organizations
CREATE TABLE organizations (
    org_id VARCHAR(50) PRIMARY KEY,
    org_name VARCHAR(255) NOT NULL,
    org_key VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Role-Process Matrix (Organization-specific)
CREATE TABLE role_process_matrix (
    id SERIAL PRIMARY KEY,
    org_id VARCHAR(50) REFERENCES organizations(org_id),
    role_id VARCHAR(50) REFERENCES role_clusters(role_id),
    process_id VARCHAR(50) REFERENCES iso_processes(process_id),
    involvement_level INT CHECK (involvement_level IN (0, 1, 2, 3)),
    UNIQUE(org_id, role_id, process_id)
);

-- Process-Competency Matrix (Static, system-wide)
CREATE TABLE process_competency_matrix (
    id SERIAL PRIMARY KEY,
    process_id VARCHAR(50) REFERENCES iso_processes(process_id),
    competency_id VARCHAR(50) REFERENCES competencies(competency_id),
    requirement_level INT CHECK (requirement_level IN (0, 1, 2)),
    UNIQUE(process_id, competency_id)
);

-- Role-Competency Matrix (Derived, auto-calculated)
CREATE TABLE role_competency_matrix (
    id SERIAL PRIMARY KEY,
    org_id VARCHAR(50) REFERENCES organizations(org_id),
    role_id VARCHAR(50) REFERENCES role_clusters(role_id),
    competency_id VARCHAR(50) REFERENCES competencies(competency_id),
    required_level INT CHECK (required_level IN (0, 1, 2, 3, 4, 6)),
    UNIQUE(org_id, role_id, competency_id)
);

-- Survey Results
CREATE TABLE survey_results (
    result_id SERIAL PRIMARY KEY,
    user_id VARCHAR(50),
    org_id VARCHAR(50) REFERENCES organizations(org_id),
    assessment_type VARCHAR(50),  -- role-based, task-based, full
    selected_roles TEXT[],  -- Array of role IDs
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Competency Assessments
CREATE TABLE competency_assessments (
    assessment_id SERIAL PRIMARY KEY,
    result_id INT REFERENCES survey_results(result_id),
    competency_id VARCHAR(50) REFERENCES competencies(competency_id),
    recorded_level INT CHECK (recorded_level IN (0, 1, 2, 3, 4, 6)),
    required_level INT CHECK (required_level IN (0, 1, 2, 3, 4, 6)),
    gap INT
);
```

### Stored Procedure for Auto-Recalculation

```sql
CREATE OR REPLACE FUNCTION recalculate_role_competency_matrix(
    p_org_id VARCHAR(50),
    p_role_id VARCHAR(50) DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    r RECORD;
BEGIN
    -- Delete existing entries for this organization (and role if specified)
    IF p_role_id IS NOT NULL THEN
        DELETE FROM role_competency_matrix 
        WHERE org_id = p_org_id AND role_id = p_role_id;
    ELSE
        DELETE FROM role_competency_matrix WHERE org_id = p_org_id;
    END IF;
    
    -- Recalculate: Role-Competency = max(Role-Process × Process-Competency)
    INSERT INTO role_competency_matrix (org_id, role_id, competency_id, required_level)
    SELECT 
        rpm.org_id,
        rpm.role_id,
        pcm.competency_id,
        MAX(rpm.involvement_level * pcm.requirement_level) as required_level
    FROM role_process_matrix rpm
    JOIN process_competency_matrix pcm ON rpm.process_id = pcm.process_id
    WHERE rpm.org_id = p_org_id
      AND (p_role_id IS NULL OR rpm.role_id = p_role_id)
    GROUP BY rpm.org_id, rpm.role_id, pcm.competency_id;
END;
$$ LANGUAGE plpgsql;
```

---

*This document provides comprehensive design and implementation details from Derik Roby's Master Thesis for integration into your SE-QPT prototype. Focus on the role mapping (Step 1.3) and competency assessment (Step 2.1) components, which are directly applicable to your qualification planning tool.*

**Last Updated:** 2025-09-30  
**For:** SE-QPT Prototype Development  
**Integration Priority:** High