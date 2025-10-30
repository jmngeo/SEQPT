/**
 * Standard SE Role Clusters (14 roles)
 * Based on SE4OWL research project
 * Used in Phase 1 Task 2: Roles & Responsibilities
 *
 * NOTE: Descriptions are brief summaries for UI display
 */

export const SE_ROLE_CLUSTERS = [
  {
    id: 1,
    name: "Customer",
    description: "Party that orders or uses the service/product with influence on system design.",
    category: "Customer"
  },
  {
    id: 2,
    name: "Customer Representative",
    description: "Interface between customer and company, voice for customer requirements.",
    category: "Customer"
  },
  {
    id: 3,
    name: "Project Manager",
    description: "Responsible for project planning, coordination, and achieving goals within constraints.",
    category: "Management"
  },
  {
    id: 4,
    name: "System Engineer",
    description: "Oversees requirements, system decomposition, interfaces, and integration planning.",
    category: "Development"
  },
  {
    id: 5,
    name: "Specialist Developer",
    description: "Develops in specific areas (software, hardware, etc.) based on system specifications.",
    category: "Development"
  },
  {
    id: 6,
    name: "Production Planner/Coordinator",
    description: "Prepares product realization and transfer to customer.",
    category: "Production"
  },
  {
    id: 7,
    name: "Production Employee",
    description: "Handles implementation, assembly, manufacture, and product integration.",
    category: "Production"
  },
  {
    id: 8,
    name: "Quality Engineer/Manager",
    description: "Ensures quality standards are maintained and cooperates with V&V.",
    category: "Quality"
  },
  {
    id: 9,
    name: "Verification and Validation (V&V) Operator",
    description: "Performs system verification and validation activities.",
    category: "Quality"
  },
  {
    id: 10,
    name: "Service Technician",
    description: "Handles installation, commissioning, training, maintenance, and repair.",
    category: "Service"
  },
  {
    id: 11,
    name: "Process and Policy Manager",
    description: "Develops internal guidelines and monitors process compliance.",
    category: "Management"
  },
  {
    id: 12,
    name: "Internal Support",
    description: "Provides advisory and support during development (IT, qualification, SE support).",
    category: "Support"
  },
  {
    id: 13,
    name: "Innovation Management",
    description: "Focuses on commercial implementation of products/services and new business models.",
    category: "Management"
  },
  {
    id: 14,
    name: "Management",
    description: "Decision-makers providing company vision, goals, and project oversight.",
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
