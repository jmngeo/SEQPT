# Task-Based Assessment: How to Write Better Task Descriptions

## Why Your Tasks Matter

The SE-QPT system uses your task descriptions to:
1. **Identify which ISO/IEC 15288 processes you perform**
2. **Calculate which competencies are required for YOUR specific role**
3. **Generate personalized feedback based on YOUR actual work**

## Problem: Vague Tasks = Wrong Assessment

### Example of What NOT to Do:
```
Responsible for: Quality assurance
Supporting: Code implementation.
Designing: Not designing any tasks
```

**Result**: LLM identifies only 1 process → Most competencies show "Not Required" → Misleading assessment

## Solution: Detailed, Specific Task Descriptions

### Example of Good Task Descriptions:

#### Software Developer (Embedded Systems)
```
Responsible for:
- Developing embedded software modules for automotive control systems
- Writing unit tests and integration tests for software components
- Creating technical documentation for software design and implementation
- Debugging and troubleshooting software issues in production environments
- Conducting code reviews for team members

Supporting:
- Collaborating with systems engineers on requirements definition
- Supporting verification and validation testing activities
- Assisting in system integration and troubleshooting
- Providing technical input during system architecture discussions

Designing:
- Designing software architecture for control modules
- Defining software interfaces between system components
- Creating detailed software design specifications
```

**Result**: LLM identifies 10-15 processes → Accurate required competency levels → Relevant feedback

#### Project Manager
```
Responsible for:
- Managing project timelines, budgets, and resource allocation
- Leading cross-functional teams (engineers, designers, testers)
- Coordinating stakeholder communication and reporting
- Tracking project risks and implementing mitigation strategies
- Ensuring compliance with quality standards and processes

Supporting:
- Supporting requirements gathering and analysis activities
- Assisting in technical feasibility assessments
- Facilitating design reviews and decision-making processes
- Helping resolve technical and organizational conflicts

Designing:
- Designing project plans and schedules
- Creating communication and governance frameworks
- Defining project metrics and KPIs
```

#### Systems Engineer
```
Responsible for:
- Defining and managing system requirements throughout lifecycle
- Conducting system-level verification and validation activities
- Managing interfaces between system components and subsystems
- Ensuring traceability from stakeholder needs to system design

Supporting:
- Supporting architectural design decisions
- Assisting in risk analysis and management
- Providing technical guidance to development teams
- Reviewing test plans and test results

Designing:
- Designing system architecture and high-level system design
- Creating system models (functional, behavioral, structural)
- Defining system-level test strategies
- Developing system integration approaches
```

## Key Principles

1. **Be Specific**: Don't just say "coding" - explain what you code, for what purpose, in what context
2. **Use SE Terminology**: If you do requirements engineering, say so explicitly
3. **Include Context**: Mention the domain (automotive, aerospace, medical devices, etc.)
4. **Distinguish Responsibilities**:
   - **Responsible for**: Tasks you own and are accountable for
   - **Supporting**: Tasks you assist others with
   - **Designing**: Tasks where you create new designs/architectures
5. **Cover the Full Lifecycle**: Include tasks from requirements → design → implementation → testing → maintenance

## Common SE Processes to Consider

When describing your tasks, think about whether you perform these processes:

### Technical Processes
- Stakeholder needs and requirements definition
- System requirements definition
- System architecture definition
- Design definition
- System analysis
- Implementation
- Integration
- Verification
- Validation
- Operation
- Maintenance
- Disposal

### Technical Management Processes
- Project planning
- Project assessment and control
- Decision management
- Risk management
- Configuration management
- Information management
- Measurement
- Quality assurance

### Organizational Project-Enabling Processes
- Life cycle model management
- Infrastructure management
- Portfolio management
- Human resource management
- Quality management

## Testing Your Task Descriptions

Before submitting, ask yourself:
1. Could someone unfamiliar with my work understand what I do?
2. Have I mentioned the main SE processes I'm involved in?
3. Have I distinguished between what I lead vs. what I support?
4. Have I covered the full scope of my role?

## Impact on Assessment Results

**Good task descriptions**:
- Identify 10-20 relevant ISO processes
- Calculate accurate required competency levels
- Generate meaningful, role-specific feedback
- Show competency gaps where they truly exist

**Poor task descriptions**:
- Identify only 1-2 processes
- Show most competencies as "Not Required"
- Generate generic feedback
- Miss important competency development areas
