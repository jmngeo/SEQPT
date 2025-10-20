"""
SE-QPT Improved Maturity Calculator (Python Backend)
Implements the enhanced 4-question maturity assessment algorithm
with balance penalty and threshold validation
"""

import math
from typing import Dict, List, Tuple


class ImprovedMaturityCalculator:
    """
    Calculator for SE maturity assessment with improved algorithm
    """

    # Field weights as per improved algorithm
    WEIGHTS = {
        'rolloutScope': 0.20,
        'seRolesProcesses': 0.35,
        'seMindset': 0.25,
        'knowledgeBase': 0.20
    }

    # Normalization mappings for each field
    NORMALIZATION_MAPS = {
        'rolloutScope': [0, 0.25, 0.50, 0.75, 1.0],
        'seRolesProcesses': [0, 0.20, 0.40, 0.60, 0.80, 1.0],
        'seMindset': [0, 0.25, 0.50, 0.75, 1.0],
        'knowledgeBase': [0, 0.25, 0.50, 0.75, 1.0]
    }

    # Maturity level definitions
    MATURITY_LEVELS = [
        {
            'level': 1,
            'name': 'Initial',
            'score_range': {'min': 0, 'max': 20},
            'color': '#DC2626',
            'description': 'Organization has minimal or no Systems Engineering capability.'
        },
        {
            'level': 2,
            'name': 'Developing',
            'score_range': {'min': 20, 'max': 40},
            'color': '#F59E0B',
            'description': 'Organization is beginning to adopt SE practices in isolated areas.'
        },
        {
            'level': 3,
            'name': 'Defined',
            'score_range': {'min': 40, 'max': 60},
            'color': '#EAB308',
            'description': 'SE processes and roles are formally defined and documented.'
        },
        {
            'level': 4,
            'name': 'Managed',
            'score_range': {'min': 60, 'max': 80},
            'color': '#10B981',
            'description': 'SE is systematically implemented company-wide with quantitative management.'
        },
        {
            'level': 5,
            'name': 'Optimized',
            'score_range': {'min': 80, 'max': 100},
            'color': '#059669',
            'description': 'SE excellence achieved with continuous optimization.'
        }
    ]

    FIELD_NAMES = {
        'rolloutScope': 'Rollout Scope',
        'seRolesProcesses': 'SE Processes & Roles',
        'seMindset': 'SE Mindset',
        'knowledgeBase': 'Knowledge Base'
    }

    @classmethod
    def calculate(cls, answers: Dict[str, int]) -> Dict:
        """
        Calculate improved maturity score

        Args:
            answers: Dictionary with keys: rolloutScope, seRolesProcesses, seMindset, knowledgeBase

        Returns:
            Dictionary with calculation results
        """
        # Step 1: Normalize values to 0-1 scale
        normalized = cls._normalize_answers(answers)

        # Step 2: Calculate weighted score (0-100)
        raw_score = cls._calculate_weighted_score(normalized)

        # Step 3: Calculate balance penalty
        penalty, std_dev, balance_score = cls._calculate_balance_penalty(normalized)

        # Step 4: Apply penalty
        score_after_penalty = raw_score - penalty

        # Step 5: Apply threshold validation
        final_score = cls._apply_thresholds(score_after_penalty, normalized)

        # Step 6: Determine maturity level
        maturity_level = cls._get_maturity_level(final_score)

        # Step 7: Get field scores
        field_scores = cls._get_field_scores(normalized)

        # Step 8: Determine profile type
        profile_type = cls._get_profile_type(normalized, std_dev)

        # Step 9: Get weakest and strongest fields
        weakest, strongest = cls._get_field_extremes(normalized)

        return {
            'rawScore': round(raw_score, 1),
            'balancePenalty': round(penalty, 1),
            'finalScore': round(final_score, 1),
            'maturityLevel': maturity_level['level'],
            'maturityName': maturity_level['name'],
            'maturityColor': maturity_level['color'],
            'maturityDescription': maturity_level['description'],
            'balanceScore': round(balance_score, 1),
            'profileType': profile_type,
            'fieldScores': field_scores,
            'weakestField': weakest,
            'strongestField': strongest,
            'normalizedValues': normalized,
            'strategyInputs': {
                'seProcessesValue': answers['seRolesProcesses'],
                'rolloutScopeValue': answers['rolloutScope']
            }
        }

    @classmethod
    def _normalize_answers(cls, answers: Dict[str, int]) -> Dict[str, float]:
        """Normalize answer values to 0-1 scale"""
        return {
            'rolloutScope': cls.NORMALIZATION_MAPS['rolloutScope'][answers['rolloutScope']],
            'seRolesProcesses': cls.NORMALIZATION_MAPS['seRolesProcesses'][answers['seRolesProcesses']],
            'seMindset': cls.NORMALIZATION_MAPS['seMindset'][answers['seMindset']],
            'knowledgeBase': cls.NORMALIZATION_MAPS['knowledgeBase'][answers['knowledgeBase']]
        }

    @classmethod
    def _calculate_weighted_score(cls, normalized: Dict[str, float]) -> float:
        """Calculate weighted average score (0-100 scale)"""
        weighted_sum = (
            normalized['rolloutScope'] * cls.WEIGHTS['rolloutScope'] +
            normalized['seRolesProcesses'] * cls.WEIGHTS['seRolesProcesses'] +
            normalized['seMindset'] * cls.WEIGHTS['seMindset'] +
            normalized['knowledgeBase'] * cls.WEIGHTS['knowledgeBase']
        )
        return weighted_sum * 100

    @classmethod
    def _calculate_balance_penalty(cls, normalized: Dict[str, float]) -> Tuple[float, float, float]:
        """Calculate balance penalty based on standard deviation"""
        values = list(normalized.values())

        # Calculate mean
        mean = sum(values) / len(values)

        # Calculate variance
        variance = sum((val - mean) ** 2 for val in values) / len(values)

        # Calculate standard deviation
        std_dev = math.sqrt(variance)

        # Penalty is std dev * 10 (max ~10%)
        penalty = std_dev * 10

        # Balance score (inverse of std dev, 0-100 scale)
        balance_score = (1 - std_dev) * 100

        return penalty, std_dev, balance_score

    @classmethod
    def _apply_thresholds(cls, score: float, normalized: Dict[str, float]) -> float:
        """Apply minimum threshold requirements"""
        min_field = min(normalized.values())

        # Level 5 (80+): All fields must be >= 0.60 (level 3)
        if score >= 80 and min_field < 0.60:
            return min(score, 79.9)

        # Level 4 (60+): All fields must be >= 0.40 (level 2)
        if score >= 60 and min_field < 0.40:
            return min(score, 59.9)

        # Level 3 (40+): All fields must be >= 0.20 (level 1)
        if score >= 40 and min_field < 0.20:
            return min(score, 39.9)

        return score

    @classmethod
    def _get_maturity_level(cls, score: float) -> Dict:
        """Determine maturity level from final score"""
        for level in cls.MATURITY_LEVELS:
            if level['score_range']['min'] <= score < level['score_range']['max']:
                return level

        # Edge case: exactly 100
        return cls.MATURITY_LEVELS[-1]

    @classmethod
    def _get_field_scores(cls, normalized: Dict[str, float]) -> Dict[str, float]:
        """Get individual field scores (0-100 scale)"""
        return {
            'rolloutScope': round(normalized['rolloutScope'] * 100, 1),
            'seRolesProcesses': round(normalized['seRolesProcesses'] * 100, 1),
            'seMindset': round(normalized['seMindset'] * 100, 1),
            'knowledgeBase': round(normalized['knowledgeBase'] * 100, 1)
        }

    @classmethod
    def _get_profile_type(cls, normalized: Dict[str, float], std_dev: float) -> str:
        """Determine profile type based on field balance and values"""
        rollout = normalized['rolloutScope']
        processes = normalized['seRolesProcesses']
        mindset = normalized['seMindset']
        knowledge = normalized['knowledgeBase']

        # Critically unbalanced (very high std dev)
        if std_dev > 0.4:
            return 'Critically Unbalanced'

        # Unbalanced development
        if std_dev > 0.3:
            return 'Unbalanced Development'

        # Balanced development (low std dev)
        if std_dev < 0.15:
            return 'Balanced Development'

        # Determine dominant field for specialized profiles
        max_value = max(rollout, processes, mindset, knowledge)

        if processes == max_value and processes > 0.6:
            return 'Process-Centric'

        if mindset == max_value and mindset > 0.6:
            return 'Culture-Centric'

        if rollout == max_value and rollout > 0.6:
            return 'Deployment-Focused'

        if knowledge == max_value and knowledge > 0.6:
            return 'Knowledge-Focused'

        return 'Balanced Development'

    @classmethod
    def _get_field_extremes(cls, normalized: Dict[str, float]) -> Tuple[Dict, Dict]:
        """Get weakest and strongest fields"""
        fields = sorted(normalized.items(), key=lambda x: x[1])

        weakest_key, weakest_value = fields[0]
        strongest_key, strongest_value = fields[-1]

        return (
            {
                'field': cls.FIELD_NAMES[weakest_key],
                'value': round(weakest_value * 100, 1)
            },
            {
                'field': cls.FIELD_NAMES[strongest_key],
                'value': round(strongest_value * 100, 1)
            }
        )

    @classmethod
    def validate_answers(cls, answers: Dict[str, int]) -> Tuple[bool, List[str]]:
        """Validate that all questions are answered"""
        errors = []

        required_fields = ['rolloutScope', 'seRolesProcesses', 'seMindset', 'knowledgeBase']

        for field in required_fields:
            if field not in answers or answers[field] is None:
                errors.append(f'Please answer the {cls.FIELD_NAMES.get(field, field)} question')

        return len(errors) == 0, errors
