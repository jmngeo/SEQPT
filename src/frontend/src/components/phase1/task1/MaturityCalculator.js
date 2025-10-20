/**
 * SE-QPT Improved Maturity Calculator
 * Implements the enhanced 4-question maturity assessment algorithm
 * with balance penalty and threshold validation
 */

export class ImprovedMaturityCalculator {
  // Field weights as per improved algorithm
  static weights = {
    rolloutScope: 0.20,
    seRolesProcesses: 0.35,
    seMindset: 0.25,
    knowledgeBase: 0.20
  };

  // Normalization mappings for each field
  static normalizationMaps = {
    rolloutScope: [0, 0.25, 0.50, 0.75, 1.0],
    seRolesProcesses: [0, 0.20, 0.40, 0.60, 0.80, 1.0],
    seMindset: [0, 0.25, 0.50, 0.75, 1.0],
    knowledgeBase: [0, 0.25, 0.50, 0.75, 1.0]
  };

  // Maturity level definitions
  static maturityLevels = [
    {
      level: 1,
      name: 'Initial',
      scoreRange: { min: 0, max: 20 },
      color: '#DC2626',
      description: 'Organization has minimal or no Systems Engineering capability.'
    },
    {
      level: 2,
      name: 'Developing',
      scoreRange: { min: 20, max: 40 },
      color: '#F59E0B',
      description: 'Organization is beginning to adopt SE practices in isolated areas.'
    },
    {
      level: 3,
      name: 'Defined',
      scoreRange: { min: 40, max: 60 },
      color: '#EAB308',
      description: 'SE processes and roles are formally defined and documented.'
    },
    {
      level: 4,
      name: 'Managed',
      scoreRange: { min: 60, max: 80 },
      color: '#10B981',
      description: 'SE is systematically implemented company-wide with quantitative management.'
    },
    {
      level: 5,
      name: 'Optimized',
      scoreRange: { min: 80, max: 100 },
      color: '#059669',
      description: 'SE excellence achieved with continuous optimization.'
    }
  ];

  /**
   * Calculate improved maturity score
   * @param {Object} answers - { rolloutScope, seRolesProcesses, seMindset, knowledgeBase }
   * @returns {Object} Calculation results
   */
  static calculate(answers) {
    // Step 1: Normalize values to 0-1 scale
    const normalized = this.normalizeAnswers(answers);

    // Step 2: Calculate weighted score (0-100)
    const rawScore = this.calculateWeightedScore(normalized);

    // Step 3: Calculate balance penalty
    const { penalty, stdDev, balanceScore } = this.calculateBalancePenalty(normalized);

    // Step 4: Apply penalty
    let scoreAfterPenalty = rawScore - penalty;

    // Step 5: Apply threshold validation
    const finalScore = this.applyThresholds(scoreAfterPenalty, normalized);

    // Step 6: Determine maturity level
    const maturityLevel = this.getMaturityLevel(finalScore);

    // Step 7: Get field scores
    const fieldScores = this.getFieldScores(normalized);

    // Step 8: Determine profile type
    const profileType = this.getProfileType(normalized, stdDev);

    // Step 9: Get weakest and strongest fields
    const { weakest, strongest } = this.getFieldExtremes(normalized);

    return {
      rawScore: parseFloat(rawScore.toFixed(1)),
      balancePenalty: parseFloat(penalty.toFixed(1)),
      finalScore: parseFloat(finalScore.toFixed(1)),
      maturityLevel: maturityLevel.level,
      maturityName: maturityLevel.name,
      maturityColor: maturityLevel.color,
      maturityDescription: maturityLevel.description,
      balanceScore: parseFloat(balanceScore.toFixed(1)),
      profileType,
      fieldScores,
      weakestField: weakest,
      strongestField: strongest,
      normalizedValues: normalized,
      // For strategy selection (Task 3) - include all raw answer values
      strategyInputs: {
        seProcessesValue: answers.seRolesProcesses,
        rolloutScopeValue: answers.rolloutScope,
        seMindsetValue: answers.seMindset,
        knowledgeBaseValue: answers.knowledgeBase
      }
    };
  }

  /**
   * Normalize answer values to 0-1 scale
   */
  static normalizeAnswers(answers) {
    return {
      rolloutScope: this.normalizationMaps.rolloutScope[answers.rolloutScope],
      seRolesProcesses: this.normalizationMaps.seRolesProcesses[answers.seRolesProcesses],
      seMindset: this.normalizationMaps.seMindset[answers.seMindset],
      knowledgeBase: this.normalizationMaps.knowledgeBase[answers.knowledgeBase]
    };
  }

  /**
   * Calculate weighted average score (0-100 scale)
   */
  static calculateWeightedScore(normalized) {
    const weightedSum =
      normalized.rolloutScope * this.weights.rolloutScope +
      normalized.seRolesProcesses * this.weights.seRolesProcesses +
      normalized.seMindset * this.weights.seMindset +
      normalized.knowledgeBase * this.weights.knowledgeBase;

    return weightedSum * 100;
  }

  /**
   * Calculate balance penalty based on standard deviation
   */
  static calculateBalancePenalty(normalized) {
    const values = Object.values(normalized);

    // Calculate mean
    const mean = values.reduce((sum, val) => sum + val, 0) / values.length;

    // Calculate variance
    const variance = values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / values.length;

    // Calculate standard deviation
    const stdDev = Math.sqrt(variance);

    // Penalty is std dev * 10 (max ~10%)
    const penalty = stdDev * 10;

    // Balance score (inverse of std dev, 0-100 scale)
    const balanceScore = (1 - stdDev) * 100;

    return { penalty, stdDev, balanceScore };
  }

  /**
   * Apply minimum threshold requirements
   */
  static applyThresholds(score, normalized) {
    const minField = Math.min(...Object.values(normalized));

    // Level 5 (80+): All fields must be >= 0.60 (level 3)
    if (score >= 80 && minField < 0.60) {
      return Math.min(score, 79.9);
    }

    // Level 4 (60+): All fields must be >= 0.40 (level 2)
    if (score >= 60 && minField < 0.40) {
      return Math.min(score, 59.9);
    }

    // Level 3 (40+): All fields must be >= 0.20 (level 1)
    if (score >= 40 && minField < 0.20) {
      return Math.min(score, 39.9);
    }

    return score;
  }

  /**
   * Determine maturity level from final score
   */
  static getMaturityLevel(score) {
    for (const level of this.maturityLevels) {
      if (score >= level.scoreRange.min && score < level.scoreRange.max) {
        return level;
      }
    }
    // Edge case: exactly 100
    return this.maturityLevels[this.maturityLevels.length - 1];
  }

  /**
   * Get individual field scores (0-100 scale)
   */
  static getFieldScores(normalized) {
    return {
      rolloutScope: parseFloat((normalized.rolloutScope * 100).toFixed(1)),
      seRolesProcesses: parseFloat((normalized.seRolesProcesses * 100).toFixed(1)),
      seMindset: parseFloat((normalized.seMindset * 100).toFixed(1)),
      knowledgeBase: parseFloat((normalized.knowledgeBase * 100).toFixed(1))
    };
  }

  /**
   * Determine profile type based on field balance and values
   */
  static getProfileType(normalized, stdDev) {
    const { rolloutScope, seRolesProcesses, seMindset, knowledgeBase } = normalized;

    // Critically unbalanced (very high std dev)
    if (stdDev > 0.4) {
      return 'Critically Unbalanced';
    }

    // Unbalanced development
    if (stdDev > 0.3) {
      return 'Unbalanced Development';
    }

    // Balanced development (low std dev)
    if (stdDev < 0.15) {
      return 'Balanced Development';
    }

    // Determine dominant field for specialized profiles
    const max = Math.max(rolloutScope, seRolesProcesses, seMindset, knowledgeBase);

    if (seRolesProcesses === max && seRolesProcesses > 0.6) {
      return 'Process-Centric';
    }

    if (seMindset === max && seMindset > 0.6) {
      return 'Culture-Centric';
    }

    if (rolloutScope === max && rolloutScope > 0.6) {
      return 'Deployment-Focused';
    }

    if (knowledgeBase === max && knowledgeBase > 0.6) {
      return 'Knowledge-Focused';
    }

    return 'Balanced Development';
  }

  /**
   * Get weakest and strongest fields
   */
  static getFieldExtremes(normalized) {
    const fields = Object.entries(normalized);

    fields.sort((a, b) => a[1] - b[1]);

    const fieldNames = {
      rolloutScope: 'Rollout Scope',
      seRolesProcesses: 'SE Processes & Roles',
      seMindset: 'SE Mindset',
      knowledgeBase: 'Knowledge Base'
    };

    return {
      weakest: {
        field: fieldNames[fields[0][0]],
        value: parseFloat((fields[0][1] * 100).toFixed(1))
      },
      strongest: {
        field: fieldNames[fields[fields.length - 1][0]],
        value: parseFloat((fields[fields.length - 1][1] * 100).toFixed(1))
      }
    };
  }

  /**
   * Validate that all questions are answered
   */
  static validateAnswers(answers) {
    const errors = [];

    if (answers.rolloutScope === undefined || answers.rolloutScope === null) {
      errors.push('Please answer the Rollout Scope question');
    }

    if (answers.seRolesProcesses === undefined || answers.seRolesProcesses === null) {
      errors.push('Please answer the SE Processes & Roles question');
    }

    if (answers.seMindset === undefined || answers.seMindset === null) {
      errors.push('Please answer the SE Mindset question');
    }

    if (answers.knowledgeBase === undefined || answers.knowledgeBase === null) {
      errors.push('Please answer the Knowledge Base question');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

export default ImprovedMaturityCalculator;
