/**
 * Standard SE Role Clusters (14 roles)
 * Based on SE4OWL research project
 * Used in Phase 1 Task 2: Identify SE Roles
 */

export const SE_ROLE_CLUSTERS = [
  {
    id: 1,
    name: "Customer",
    description: "Client for the development, has impact on system design",
    category: "Customer"
  },
  {
    id: 2,
    name: "Customer Representative",
    description: "Interface between customer and company, voice for customer-relevant information",
    category: "Customer"
  },
  {
    id: 3,
    name: "Project Manager",
    description: "Planning and coordinating projects, monitoring resources and objectives",
    category: "Management"
  },
  {
    id: 4,
    name: "System Engineer",
    description: "Overview of requirements, system decomposition, integration and interfaces",
    category: "Development"
  },
  {
    id: 5,
    name: "Specialist Developer",
    description: "Various specialist areas (software, hardware, etc.) developing based on system specifications",
    category: "Development"
  },
  {
    id: 6,
    name: "Production Planner/Coordinator",
    description: "Preparation of product realization and transfer to customer",
    category: "Production"
  },
  {
    id: 7,
    name: "Production Employee",
    description: "Implementation, assembly, manufacture through to goods issue and shipping",
    category: "Production"
  },
  {
    id: 8,
    name: "Quality Engineer/Manager",
    description: "Ensuring quality standards are maintained, cooperation with V&V",
    category: "Quality"
  },
  {
    id: 9,
    name: "Verification and Validation (V&V) Operator",
    description: "System verification and validation activities",
    category: "Quality"
  },
  {
    id: 10,
    name: "Service Technician",
    description: "Installation, commissioning, user training, maintenance and repair",
    category: "Service"
  },
  {
    id: 11,
    name: "Process and Policy Manager",
    description: "Developing internal guidelines for process flows and monitoring compliance",
    category: "Management"
  },
  {
    id: 12,
    name: "Internal Support",
    description: "Support during development (IT, qualification, SE support)",
    category: "Support"
  },
  {
    id: 13,
    name: "Innovation Management",
    description: "Commercial implementation of products/services, new business models",
    category: "Management"
  },
  {
    id: 14,
    name: "Management",
    description: "Company vision and goals, crucial for project progress",
    category: "Management"
  }
];

/**
 * Target group size categories with implications
 */
export const TARGET_GROUP_SIZES = [
  {
    id: 'small',
    range: '< 20',
    category: 'SMALL',
    label: 'Less than 20 people',
    description: 'Small group - suitable for intensive workshops',
    value: 10,
    implications: {
      formats: ['Workshop', 'Coaching', 'Mentoring'],
      approach: 'Direct intensive training',
      trainTheTrainer: false
    }
  },
  {
    id: 'medium',
    range: '20-100',
    category: 'MEDIUM',
    label: '20 - 100 people',
    description: 'Medium group - mixed format approach recommended',
    value: 60,
    implications: {
      formats: ['Workshop', 'Blended Learning', 'Group Projects'],
      approach: 'Mixed format with cohorts',
      trainTheTrainer: false
    }
  },
  {
    id: 'large',
    range: '100-500',
    category: 'LARGE',
    label: '100 - 500 people',
    description: 'Large group - consider train-the-trainer approach',
    value: 300,
    implications: {
      formats: ['Blended Learning', 'E-Learning', 'Train-the-Trainer'],
      approach: 'Scalable formats required',
      trainTheTrainer: true
    }
  },
  {
    id: 'xlarge',
    range: '500-1500',
    category: 'VERY_LARGE',
    label: '500 - 1500 people',
    description: 'Very large group - phased rollout recommended',
    value: 1000,
    implications: {
      formats: ['E-Learning', 'Train-the-Trainer', 'Self-paced'],
      approach: 'Phased rollout with trainers',
      trainTheTrainer: true
    }
  },
  {
    id: 'xxlarge',
    range: '> 1500',
    category: 'ENTERPRISE',
    label: 'More than 1500 people',
    description: 'Enterprise scale - comprehensive program required',
    value: 2000,
    implications: {
      formats: ['E-Learning Platform', 'Train-the-Trainer', 'Learning Management System'],
      approach: 'Enterprise learning program',
      trainTheTrainer: true
    }
  }
];
