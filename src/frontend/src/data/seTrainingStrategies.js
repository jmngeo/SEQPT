/**
 * SE Training Strategies Data
 * Note: The full strategy definitions are fetched from the backend API
 * This file contains category information and Pro/Con comparisons for the UI
 */

export const STRATEGY_CATEGORIES = {
  FOUNDATIONAL: { label: 'Foundational', color: '#1976D2' },
  AWARENESS: { label: 'Awareness', color: '#388E3C' },
  APPLICATION: { label: 'Application', color: '#F57C00' },
  SPECIALIZATION: { label: 'Specialization', color: '#7B1FA2' },
  SUSTAINMENT: { label: 'Sustainment', color: '#0097A7' },
  TARGETED: { label: 'Targeted', color: '#C62828' },
  MULTIPLIER: { label: 'Multiplier', color: '#5D4037' }
}

export const PRIORITY_BADGES = {
  PRIMARY: { label: 'Primary', color: 'primary', icon: 'mdi-star' },
  SECONDARY: { label: 'Secondary', color: 'info', icon: 'mdi-star-half-full' },
  SUPPLEMENTARY: { label: 'Supplementary', color: 'success', icon: 'mdi-plus-circle' }
}

/**
 * Pro-Con Comparison Data for Low-Maturity Secondary Strategy Selection
 * Used when seProcessesValue <= 1
 */
export const STRATEGY_PRO_CON = {
  common_understanding: {
    name: 'Common Basic Understanding',
    description: 'Interdisciplinary exchange creating SE awareness through basic training',
    pros: [
      'Standardized vocabulary across organization',
      'Low barrier to entry for all participants',
      'Breaking down silo thinking',
      'Broad participation possible (10-100 people)'
    ],
    cons: [
      'No direct project reference',
      'Little depth of technical content',
      'Less acceptance without practical context'
    ],
    bestFor: 'Organizations needing broad SE awareness across multiple departments'
  },

  orientation_pilot: {
    name: 'Orientation in Pilot Project',
    description: 'Application-oriented qualification through SE pilot project experience',
    pros: [
      'High acceptance through visible results',
      'Measurable benefit demonstration',
      'Direct testing of content in practice',
      'Motivation through visible success'
    ],
    cons: [
      'Effectiveness depends on project selection',
      'Not useful for all roles',
      'Time pressure on project makes learning difficult',
      'Requires suitable pilot project'
    ],
    bestFor: 'Organizations with active development projects and available teams'
  },

  certification: {
    name: 'Certification (SE-Zert, CSEP)',
    description: 'Standardized certification training for creating internal SE experts',
    pros: [
      'High international standard',
      'International recognition (SE-Zert, CSEP, INCOSE)',
      'Technical depth and rigor',
      'Ideal for creating specialists'
    ],
    cons: [
      'No direct project reference',
      'Low transferability without company-wide SE introduction',
      'Cost-intensive investment'
    ],
    bestFor: 'Organizations wanting to establish a core team of certified SE experts'
  }
}

/**
 * Get category information for a strategy
 */
export function getCategoryInfo(categoryKey) {
  return STRATEGY_CATEGORIES[categoryKey] || { label: categoryKey, color: '#757575' }
}

/**
 * Get priority badge information
 */
export function getPriorityInfo(priorityKey) {
  return PRIORITY_BADGES[priorityKey] || { label: priorityKey, color: 'default', icon: 'mdi-circle' }
}
