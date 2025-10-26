# SE-QPT Phase 1 Restructuring: Complete Implementation Guide

## Phase 1: Analyze and Identify - Correct Task Order

### Task Flow Overview
```
1. Assess SE Maturity Level (✅ Complete)
   ↓
2. Identify SE Roles (Current Focus)
   ↓
3. Select SE Training Strategy
   ↓
Phase 1 Deliverables: SE Maturity Level, SE Roles List, SE Training Strategy
```

## Task 2: Identify SE Roles - Detailed Implementation

### 2.1 Decision Logic Based on Maturity Assessment

The SE Roles identification process depends on the `seRolesProcesses` maturity field value from Task 1:

```javascript
// Determine pathway based on maturity assessment
const determineRoleIdentificationPathway = (seProcessesValue) => {
  const MATURITY_THRESHOLD = 3; // "Defined and Established"
  
  if (seProcessesValue >= MATURITY_THRESHOLD) {
    return 'STANDARD_ROLES_PATHWAY';
  } else {
    return 'TASK_BASED_PATHWAY';
  }
};
```

**Note on Role Clusters**: The SE-QPT system uses 14 standard SE role clusters based on the SE4OWL research project. These role clusters represent comprehensive coverage of all SE-related functions in an organization.

### 2.2 Standard SE Role Clusters (14 Roles)

```javascript
const SE_ROLE_CLUSTERS = [
  {
    id: 1,
    name: "Customer",
    description: "Client for the development, has impact on system design"
  },
  {
    id: 2,
    name: "Customer Representative",
    description: "Interface between customer and company, voice for customer-relevant information"
  },
  {
    id: 3,
    name: "Project Manager",
    description: "Planning and coordinating projects, monitoring resources and objectives"
  },
  {
    id: 4,
    name: "System Engineer",
    description: "Overview of requirements, system decomposition, integration and interfaces"
  },
  {
    id: 5,
    name: "Specialist Developer",
    description: "Various specialist areas (software, hardware, etc.) developing based on system specifications"
  },
  {
    id: 6,
    name: "Production Planner/Coordinator",
    description: "Preparation of product realization and transfer to customer"
  },
  {
    id: 7,
    name: "Production Employee",
    description: "Implementation, assembly, manufacture through to goods issue and shipping"
  },
  {
    id: 8,
    name: "Quality Engineer/Manager",
    description: "Ensuring quality standards are maintained, cooperation with V&V"
  },
  {
    id: 9,
    name: "Verification and Validation (V&V) Operator",
    description: "System verification and validation activities"
  },
  {
    id: 10,
    name: "Service Technician",
    description: "Installation, commissioning, user training, maintenance and repair"
  },
  {
    id: 11,
    name: "Process and Policy Manager",
    description: "Developing internal guidelines for process flows and monitoring compliance"
  },
  {
    id: 12,
    name: "Internal Support",
    description: "Support during development (IT, qualification, SE support)"
  },
  {
    id: 13,
    name: "Innovation Management",
    description: "Commercial implementation of products/services, new business models"
  },
  {
    id: 14,
    name: "Management",
    description: "Company vision and goals, crucial for project progress"
  }
];
```

## Implementation Pathways

### Pathway A: High Maturity Organizations (seRolesProcesses ≥ 3)

**Step A1: Display Standard Roles**
```javascript
// UI Component: Role Selection Interface
const StandardRoleSelection = () => {
  // Display all 14 SE Role Clusters with:
  // - Checkbox for selection
  // - Role name and description
  // - Input field for organization-specific name adaptation
  
  return (
    <div className="role-selection-container">
      <h3>Select SE Roles in Your Organization</h3>
      <p>Your organization has defined SE processes. Please identify which roles 
         participate in or are affected by the SE training program.</p>
      <p className="info-text">Select from the 14 standard SE role clusters below:</p>
      
      {SE_ROLE_CLUSTERS.map(role => (
        <div key={role.id} className="role-item">
          <input type="checkbox" id={`role-${role.id}`} />
          <label>{role.name}</label>
          <p className="description">{role.description}</p>
          <input 
            type="text" 
            placeholder="Your organization's name for this role"
            className="org-name-input"
          />
        </div>
      ))}
      
      <div className="selection-summary">
        <p>Roles selected: <span className="count">0</span> / 14</p>
      </div>
    </div>
  );
};
```

**Step A2: Role Adaptation**
```javascript
const adaptRolesToOrganization = (selectedRoles) => {
  return selectedRoles.map(role => ({
    standardRoleId: role.id,
    standardRoleName: role.name,
    organizationRoleName: role.customName || role.name,
    isParticipatingInTraining: true,
    estimatedHeadcount: null // To be filled in Phase 2
  }));
};
```

### Pathway B: Low Maturity Organizations (seRolesProcesses < 3)

**Step B1: Collect Job Profiles (Multiple Input Support)**
```javascript
// UI Component: Job Profile Input with Multiple Profile Support
const JobProfileCollection = () => {
  const [jobProfiles, setJobProfiles] = useState([]);
  
  return (
    <div className="job-profile-container">
      <h3>Describe Your Organization's Job Profiles</h3>
      <p>Since your SE processes are still developing, please describe the 
         job profiles that exist in your organization. You can add multiple profiles.</p>
      
      <form id="job-profiles-form">
        {jobProfiles.map((profile, index) => (
          <div key={index} className="job-profile-card">
            <h4>Job Profile #{index + 1}</h4>
            <input type="text" placeholder="Job Title" value={profile.title} />
            <textarea placeholder="Main responsibilities and tasks" value={profile.responsibilities} />
            <textarea placeholder="Typical activities (list key tasks)" value={profile.activities} />
            <select value={profile.department}>
              <option>Department/Area</option>
              <option>Engineering</option>
              <option>Production</option>
              <option>Quality</option>
              <option>Management</option>
              <option>Support</option>
            </select>
            <button type="button" onClick={() => removeProfile(index)}>Remove</button>
          </div>
        ))}
        
        <button type="button" onClick={addNewProfile} className="add-profile-btn">
          + Add Another Job Profile
        </button>
      </form>
      
      <div className="profile-summary">
        <p>Total Job Profiles Added: {jobProfiles.length}</p>
        <p className="info-text">
          💡 Add all job profiles that will be affected by the SE training program.
          The system will map each profile to appropriate SE roles.
        </p>
      </div>
    </div>
  );
};

// Supporting functions
const addNewProfile = () => {
  setJobProfiles([...jobProfiles, {
    title: '',
    responsibilities: '',
    activities: '',
    department: ''
  }]);
};

const removeProfile = (index) => {
  setJobProfiles(jobProfiles.filter((_, i) => i !== index));
};
```

**Step B2: Task-Based Assessment Integration (Multiple Profiles)**
```javascript
// Integrate Derik's Task-Based Competency Assessor for Multiple Job Profiles
const TaskBasedRoleMapping = async (jobProfiles) => {
  const mappedRoles = [];
  
  // Process each job profile individually
  for (const profile of jobProfiles) {
    // Step 1: Extract tasks from job description
    const tasks = await extractTasksFromDescription(profile);
    
    // Step 2: Map tasks to ISO 15288 processes using AI
    const isoProcesses = await mapTasksToISO15288(tasks);
    
    // Step 3: Use Role-Process Matrix to identify best matching SE roles
    const matchedRoles = calculateRoleMatches(isoProcesses);
    
    // Step 4: Create mapping
    mappedRoles.push({
      organizationJobTitle: profile.title,
      matchedSERoles: matchedRoles,
      confidenceScore: matchedRoles[0].score,
      suggestedPrimaryRole: matchedRoles[0].roleId,
      tasks: tasks,
      isoProcesses: isoProcesses
    });
  }
  
  // Step 5: Consolidate multiple profiles if they map to same SE role
  const consolidatedRoles = consolidateMappings(mappedRoles);
  
  return consolidatedRoles;
};

// Consolidate multiple job profiles that map to the same SE role
const consolidateMappings = (mappedRoles) => {
  const roleGroups = {};
  
  mappedRoles.forEach(mapping => {
    const roleId = mapping.suggestedPrimaryRole;
    if (!roleGroups[roleId]) {
      roleGroups[roleId] = {
        standardRoleId: roleId,
        organizationProfiles: [],
        averageConfidence: 0,
        combinedTasks: new Set(),
        affectedHeadcount: 0
      };
    }
    
    roleGroups[roleId].organizationProfiles.push({
      title: mapping.organizationJobTitle,
      confidence: mapping.confidenceScore
    });
    
    mapping.tasks.forEach(task => roleGroups[roleId].combinedTasks.add(task));
  });
  
  // Calculate average confidence for consolidated roles
  Object.values(roleGroups).forEach(group => {
    const totalConfidence = group.organizationProfiles.reduce(
      (sum, profile) => sum + profile.confidence, 0
    );
    group.averageConfidence = totalConfidence / group.organizationProfiles.length;
  });
  
  return roleGroups;
};

// AI-powered task extraction and mapping
const extractTasksFromDescription = async (profile) => {
  // Use NLP to extract actionable tasks from job description
  const prompt = `
    Extract specific SE-related tasks from this job profile:
    Title: ${profile.title}
    Responsibilities: ${profile.responsibilities}
    Activities: ${profile.activities}
    
    Return tasks categorized by involvement level:
    - Responsible for
    - Supporting
    - Designing/Improving
  `;
  
  return await callAIService(prompt);
};

const mapTasksToISO15288 = async (tasks) => {
  // Map extracted tasks to ISO 15288 processes
  const ISO_PROCESSES = [
    'Stakeholder Requirements Definition',
    'Requirements Analysis', 
    'Architectural Design',
    'Implementation',
    'Integration',
    'Verification',
    'Validation',
    'Operation',
    'Maintenance',
    'Disposal',
    'Project Planning',
    'Project Assessment and Control',
    'Decision Management',
    'Risk Management',
    'Configuration Management',
    'Information Management',
    'Measurement',
    'Quality Assurance'
    // ... (complete list of 30 ISO 15288 processes)
  ];
  
  return await matchTasksToProcesses(tasks, ISO_PROCESSES);
};
```

**Step B3: Role Confirmation and Adaptation**
```javascript
const confirmMappedRoles = (mappedRoles) => {
  return (
    <div className="role-confirmation">
      <h3>Confirm SE Role Mappings</h3>
      <p>Based on your job profiles, we've identified the following SE roles:</p>
      
      {mappedRoles.map(mapping => (
        <div key={mapping.organizationJobTitle} className="mapping-item">
          <h4>{mapping.organizationJobTitle}</h4>
          <p>Maps to SE Role: <strong>{mapping.suggestedPrimaryRole}</strong></p>
          <p>Confidence: {mapping.confidenceScore}%</p>
          
          <div className="actions">
            <button>Confirm</button>
            <button>Select Different Role</button>
            <input 
              type="text" 
              placeholder="Adapt role name for your organization"
            />
          </div>
        </div>
      ))}
    </div>
  );
};
```

## Final Step: Target Group Size Assessment

After role identification (both pathways), the system collects information about the training target group size:

```javascript
// Component: Target Group Size Question
const TargetGroupSizeAssessment = () => {
  const [targetGroupSize, setTargetGroupSize] = useState('');
  
  return (
    <div className="target-group-container">
      <h3>Training Target Group Size</h3>
      <p className="question">How large is the target group for the SE training project?</p>
      <p className="sub-text">This helps determine the appropriate training formats and resource allocation.</p>
      
      <div className="size-options">
        <label className="size-option">
          <input 
            type="radio" 
            value="small" 
            onChange={(e) => setTargetGroupSize(e.target.value)}
            name="targetSize"
          />
          <span className="option-text">Less than 20 people</span>
          <span className="option-detail">Small group - suitable for intensive workshops</span>
        </label>
        
        <label className="size-option">
          <input 
            type="radio" 
            value="medium" 
            onChange={(e) => setTargetGroupSize(e.target.value)}
            name="targetSize"
          />
          <span className="option-text">20 - 100 people</span>
          <span className="option-detail">Medium group - mixed format approach recommended</span>
        </label>
        
        <label className="size-option">
          <input 
            type="radio" 
            value="large" 
            onChange={(e) => setTargetGroupSize(e.target.value)}
            name="targetSize"
          />
          <span className="option-text">100 - 500 people</span>
          <span className="option-detail">Large group - consider train-the-trainer approach</span>
        </label>
        
        <label className="size-option">
          <input 
            type="radio" 
            value="xlarge" 
            onChange={(e) => setTargetGroupSize(e.target.value)}
            name="targetSize"
          />
          <span className="option-text">500 - 1500 people</span>
          <span className="option-detail">Very large group - phased rollout recommended</span>
        </label>
        
        <label className="size-option">
          <input 
            type="radio" 
            value="xxlarge" 
            onChange={(e) => setTargetGroupSize(e.target.value)}
            name="targetSize"
          />
          <span className="option-text">More than 1500 people</span>
          <span className="option-detail">Enterprise scale - comprehensive program required</span>
        </label>
      </div>
      
      <button 
        className="continue-btn"
        disabled={!targetGroupSize}
        onClick={() => proceedToStrategySelection(targetGroupSize)}
      >
        Continue to Strategy Selection
      </button>
    </div>
  );
};

// Function to store target group size and proceed
const proceedToStrategySelection = (size) => {
  const sizeMapping = {
    'small': { range: '< 20', value: 10, category: 'SMALL' },
    'medium': { range: '20-100', value: 60, category: 'MEDIUM' },
    'large': { range: '100-500', value: 300, category: 'LARGE' },
    'xlarge': { range: '500-1500', value: 1000, category: 'VERY_LARGE' },
    'xxlarge': { range: '> 1500', value: 2000, category: 'ENTERPRISE' }
  };
  
  // Store for use in strategy selection
  return {
    targetGroupSize: sizeMapping[size],
    implicationsForStrategy: determineStrategyImplications(sizeMapping[size])
  };
};

// Determine strategy implications based on group size
const determineStrategyImplications = (sizeData) => {
  const implications = {
    'SMALL': {
      formats: ['Workshop', 'Coaching', 'Mentoring'],
      approach: 'Direct intensive training',
      trainTheTrainer: false
    },
    'MEDIUM': {
      formats: ['Workshop', 'Blended Learning', 'Group Projects'],
      approach: 'Mixed format with cohorts',
      trainTheTrainer: 'optional'
    },
    'LARGE': {
      formats: ['Blended Learning', 'E-Learning', 'Train-the-Trainer'],
      approach: 'Scalable formats required',
      trainTheTrainer: true
    },
    'VERY_LARGE': {
      formats: ['E-Learning', 'Train-the-Trainer', 'Self-paced'],
      approach: 'Phased rollout with trainers',
      trainTheTrainer: true
    },
    'ENTERPRISE': {
      formats: ['E-Learning Platform', 'Train-the-Trainer', 'Learning Management System'],
      approach: 'Enterprise learning program',
      trainTheTrainer: true
    }
  };
  
  return implications[sizeData.category];
};
```

## Database Schema for Role Identification

```sql
-- Organization Roles Table
CREATE TABLE organization_roles (
  id INTEGER PRIMARY KEY,
  org_id INTEGER FOREIGN KEY,
  assessment_id INTEGER FOREIGN KEY,
  standard_role_id INTEGER,
  standard_role_name VARCHAR(100),
  organization_role_name VARCHAR(100),
  job_description TEXT,
  main_tasks TEXT,
  department VARCHAR(50),
  participating_in_training BOOLEAN,
  identification_method VARCHAR(20), -- 'STANDARD' or 'TASK_BASED'
  confidence_score DECIMAL(3,1),
  created_date TIMESTAMP
);

-- Role-Task Mapping Table (for low maturity orgs)
CREATE TABLE role_task_mappings (
  id INTEGER PRIMARY KEY,
  org_role_id INTEGER FOREIGN KEY,
  task_description TEXT,
  involvement_level VARCHAR(20), -- 'RESPONSIBLE', 'SUPPORTING', 'DESIGNING'
  iso_process VARCHAR(100),
  ai_confidence DECIMAL(3,1)
);

-- Target Group Size Table
CREATE TABLE training_target_group (
  id INTEGER PRIMARY KEY,
  org_id INTEGER FOREIGN KEY,
  assessment_id INTEGER FOREIGN KEY,
  size_range VARCHAR(20), -- '< 20', '20-100', '100-500', '500-1500', '> 1500'
  size_category VARCHAR(20), -- 'SMALL', 'MEDIUM', 'LARGE', 'VERY_LARGE', 'ENTERPRISE'
  estimated_count INTEGER,
  total_roles_identified INTEGER,
  created_date TIMESTAMP
);
```

## Integration Points with Existing SE-QPT

### 1. Input from Maturity Assessment (Task 1)
```javascript
const maturityData = {
  seRolesProcesses: 2, // Example: "Individually Controlled"
  overallMaturityLevel: 2,
  maturityName: "Developing"
};
```

### 2. Output to Strategy Selection (Task 3)
```javascript
const identifiedRoles = {
  totalRolesIdentified: 7,
  rolesList: [
    {
      id: 1,
      standardRole: "Project Manager",
      orgName: "Product Lead",
      headcount: null // Filled in Phase 2
    },
    // ... more roles
  ],
  identificationMethod: "TASK_BASED",
  requiresValidation: true,
  targetGroupSize: {
    range: '100-500',
    category: 'LARGE',
    estimatedCount: 300,
    strategyImplications: {
      formats: ['Blended Learning', 'E-Learning', 'Train-the-Trainer'],
      approach: 'Scalable formats required',
      trainTheTrainer: true
    }
  }
};
```

### 3. Output to Phase 2 (Competency Assessment)
```javascript
const phaseOneOutput = {
  maturityLevel: maturityData,
  identifiedRoles: identifiedRoles,
  targetGroupSize: identifiedRoles.targetGroupSize,
  trainingStrategy: null, // From Task 3
  
  // Passed to Phase 2
  competencyAssessmentConfig: {
    assessmentPathway: identifiedRoles.identificationMethod === 'TASK_BASED' 
      ? 'TASK_BASED' 
      : 'ROLE_BASED',
    rolesToAssess: identifiedRoles.rolesList,
    scaleFactor: identifiedRoles.targetGroupSize.category
  }
};
```

## API Endpoints

```javascript
// Role identification endpoints
POST /api/roles/identify
GET /api/roles/standard-clusters
POST /api/roles/map-tasks
POST /api/roles/confirm-mapping
GET /api/roles/organization/{org_id}
POST /api/roles/target-group-size

// Integration with AI service
POST /api/ai/extract-tasks
POST /api/ai/map-to-iso-processes
POST /api/ai/calculate-role-similarity

// Target group endpoints
POST /api/training/target-group
GET /api/training/size-recommendations/{size_category}
```

## Error Handling and Edge Cases

```javascript
const handleRoleIdentificationErrors = {
  noRolesSelected: "Please select at least one role for training",
  lowConfidenceMapping: "Manual review required for roles with <65% confidence",
  duplicateRoles: "Multiple job profiles map to the same SE role",
  unmappableRole: "Unable to map this job profile to any SE role",
  noTargetGroupSize: "Please specify the target group size for training",
  
  validationRules: {
    minRoles: 1,
    maxRoles: 14, // Total number of standard SE role clusters
    minConfidence: 0.65,
    requiresManualReview: (confidence) => confidence < 0.65,
    maxJobProfiles: 50, // Reasonable limit for input
    targetGroupRequired: true
  }
};
```

## Next Steps: Task 3 - Select SE Training Strategy

After completing role identification, the system proceeds to strategy selection using:
- Maturity level (from Task 1)
- Number and types of roles identified (from Task 2)
- **Target group size** (from Task 2 final step)
- Organization size and resources (collected in Task 3)

The decision tree for strategy selection will utilize these inputs to recommend one or more qualification archetypes. The target group size particularly influences:
- Whether "Train-the-Trainer" archetype should be added
- Selection of appropriate learning formats (workshops vs. e-learning)
- Phasing and rollout approach for the training program

### Key Decision Rules Based on Target Group Size:
- **< 20 people**: Direct intensive training, workshops, coaching
- **20-100 people**: Mixed formats, cohort-based approach
- **100-500 people**: Scalable formats, consider Train-the-Trainer
- **500-1500 people**: Phased rollout, Train-the-Trainer essential
- **> 1500 people**: Enterprise learning program, LMS implementation