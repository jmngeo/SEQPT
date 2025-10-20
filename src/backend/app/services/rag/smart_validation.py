"""
SMART Criteria Validation System
Validates learning objectives against SMART criteria with ≥85% quality threshold
Core quality assurance component of RAG-LLM innovation
"""

import os
import json
import logging
import re
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
from dataclasses import dataclass, asdict
from pydantic import BaseModel, Field
from company_context_extractor import CompanyPMTContext

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class SMARTScore:
    """Individual SMART criterion score"""
    criterion: str
    score: float  # 0.0 to 1.0
    justification: str
    improvement_suggestions: List[str] = None

    def __post_init__(self):
        if self.improvement_suggestions is None:
            self.improvement_suggestions = []

@dataclass
class QualityAssessment:
    """Complete quality assessment of a learning objective"""
    objective_text: str
    competency: str
    company_context: str

    # Individual SMART scores
    specific_score: SMARTScore
    measurable_score: SMARTScore
    achievable_score: SMARTScore
    relevant_score: SMARTScore
    time_bound_score: SMARTScore

    # Additional criteria
    company_alignment_score: SMARTScore
    incose_compliance_score: SMARTScore
    business_value_score: SMARTScore

    # Overall metrics
    smart_average: float = 0.0
    overall_quality: float = 0.0
    meets_threshold: bool = False
    quality_threshold: float = 0.85

    # Recommendations
    strengths: List[str] = None
    weaknesses: List[str] = None
    improvement_plan: List[str] = None

    def __post_init__(self):
        if self.strengths is None:
            self.strengths = []
        if self.weaknesses is None:
            self.weaknesses = []
        if self.improvement_plan is None:
            self.improvement_plan = []

        # Calculate averages
        self._calculate_scores()

    def _calculate_scores(self):
        """Calculate overall scores"""
        # SMART average (equal weight)
        smart_scores = [
            self.specific_score.score,
            self.measurable_score.score,
            self.achievable_score.score,
            self.relevant_score.score,
            self.time_bound_score.score
        ]
        self.smart_average = sum(smart_scores) / len(smart_scores)

        # Overall quality (weighted)
        self.overall_quality = (
            self.smart_average * 0.6 +  # SMART criteria: 60%
            self.company_alignment_score.score * 0.20 +  # Company alignment: 20%
            self.incose_compliance_score.score * 0.10 +  # INCOSE compliance: 10%
            self.business_value_score.score * 0.10  # Business value: 10%
        )

        # Check threshold
        self.meets_threshold = self.overall_quality >= self.quality_threshold

class SMARTValidator:
    """Advanced SMART criteria validation with company context awareness"""

    def __init__(self, quality_threshold: float = 0.85):
        self.quality_threshold = quality_threshold
        self.validation_patterns = self._initialize_validation_patterns()
        self.scoring_criteria = self._initialize_scoring_criteria()
        logger.info(f"SMART Validator initialized with {quality_threshold:.1%} quality threshold")

    def validate_objective(
        self,
        objective_text: str,
        competency: str,
        company_context: CompanyPMTContext,
        archetype: str = "",
        role: str = ""
    ) -> QualityAssessment:
        """Comprehensive validation of learning objective against SMART criteria"""

        try:
            # Validate individual SMART criteria
            specific_score = self._validate_specific(objective_text, competency, company_context)
            measurable_score = self._validate_measurable(objective_text, competency)
            achievable_score = self._validate_achievable(objective_text, company_context, archetype)
            relevant_score = self._validate_relevant(objective_text, competency, company_context, role)
            time_bound_score = self._validate_time_bound(objective_text, archetype)

            # Validate additional criteria
            company_alignment_score = self._validate_company_alignment(objective_text, company_context)
            incose_compliance_score = self._validate_incose_compliance(objective_text, competency)
            business_value_score = self._validate_business_value(objective_text, company_context)

            # Create assessment
            assessment = QualityAssessment(
                objective_text=objective_text,
                competency=competency,
                company_context=f"{company_context.company_name} - {company_context.industry_domain}",
                specific_score=specific_score,
                measurable_score=measurable_score,
                achievable_score=achievable_score,
                relevant_score=relevant_score,
                time_bound_score=time_bound_score,
                company_alignment_score=company_alignment_score,
                incose_compliance_score=incose_compliance_score,
                business_value_score=business_value_score,
                quality_threshold=self.quality_threshold
            )

            # Generate recommendations
            self._generate_recommendations(assessment)

            logger.info(f"Validated objective with quality score: {assessment.overall_quality:.2f}")
            return assessment

        except Exception as e:
            logger.error(f"Error validating objective: {e}")
            return self._get_default_assessment(objective_text, competency)

    def _validate_specific(self, objective_text: str, competency: str, company_context: CompanyPMTContext) -> SMARTScore:
        """Validate Specific criterion"""
        score = 0.0
        justification_parts = []
        suggestions = []

        # Check for clear action verbs
        action_verbs = ['understand', 'apply', 'analyze', 'create', 'evaluate', 'demonstrate', 'implement', 'design']
        has_action_verb = any(verb in objective_text.lower() for verb in action_verbs)
        if has_action_verb:
            score += 0.25
            justification_parts.append("Contains clear action verb")
        else:
            suggestions.append("Add specific action verb (understand, apply, demonstrate, etc.)")

        # Check for specific scope/context
        if company_context.company_name.lower() in objective_text.lower():
            score += 0.25
            justification_parts.append("References company context")
        else:
            suggestions.append(f"Include reference to {company_context.company_name}'s context")

        # Check for competency-specific content
        if competency.lower() in objective_text.lower():
            score += 0.25
            justification_parts.append("Addresses target competency")
        else:
            suggestions.append(f"Explicitly mention {competency} competency")

        # Check for specific tools/processes
        has_specific_tools = any(tool.lower() in objective_text.lower() for tool in company_context.tools)
        has_specific_processes = any(proc.lower() in objective_text.lower() for proc in company_context.processes)
        if has_specific_tools or has_specific_processes:
            score += 0.25
            justification_parts.append("References specific tools/processes")
        else:
            suggestions.append("Include specific tools or processes used by the company")

        justification = "; ".join(justification_parts) if justification_parts else "Lacks specific details"

        return SMARTScore(
            criterion="Specific",
            score=min(score, 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _validate_measurable(self, objective_text: str, competency: str) -> SMARTScore:
        """Validate Measurable criterion"""
        score = 0.0
        justification_parts = []
        suggestions = []

        # Check for measurable verbs
        measurable_verbs = ['demonstrate', 'identify', 'create', 'analyze', 'evaluate', 'implement', 'complete']
        has_measurable_verb = any(verb in objective_text.lower() for verb in measurable_verbs)
        if has_measurable_verb:
            score += 0.3
            justification_parts.append("Contains measurable action verbs")
        else:
            suggestions.append("Use measurable verbs (demonstrate, identify, create, etc.)")

        # Check for observable outcomes
        observable_patterns = [
            r'by\s+\w+ing',  # "by implementing", "by creating"
            r'through\s+\w+',  # "through analysis"
            r'using\s+\w+',  # "using DOORS"
            r'will\s+be\s+able\s+to',  # Standard format
        ]
        has_observable = any(re.search(pattern, objective_text, re.IGNORECASE) for pattern in observable_patterns)
        if has_observable:
            score += 0.3
            justification_parts.append("Describes observable outcomes")
        else:
            suggestions.append("Include observable outcomes or deliverables")

        # Check for success criteria
        success_indicators = ['successfully', 'correctly', 'effectively', 'accurately', 'completely']
        has_success_criteria = any(indicator in objective_text.lower() for indicator in success_indicators)
        if has_success_criteria:
            score += 0.2
            justification_parts.append("Includes success criteria")
        else:
            suggestions.append("Add success criteria (successfully, effectively, etc.)")

        # Check for deliverables/artifacts
        deliverable_words = ['document', 'model', 'plan', 'analysis', 'design', 'report', 'specification']
        has_deliverables = any(word in objective_text.lower() for word in deliverable_words)
        if has_deliverables:
            score += 0.2
            justification_parts.append("Specifies deliverables/artifacts")
        else:
            suggestions.append("Specify concrete deliverables or artifacts")

        justification = "; ".join(justification_parts) if justification_parts else "Lacks measurable outcomes"

        return SMARTScore(
            criterion="Measurable",
            score=min(score, 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _validate_achievable(self, objective_text: str, company_context: CompanyPMTContext, archetype: str) -> SMARTScore:
        """Validate Achievable criterion"""
        score = 0.5  # Base score assuming reasonable objective
        justification_parts = ["Objective appears reasonable in scope"]
        suggestions = []

        # Check complexity against maturity level
        complexity_indicators = ['complex', 'advanced', 'sophisticated', 'comprehensive', 'master']
        has_complexity = any(indicator in objective_text.lower() for indicator in complexity_indicators)

        if has_complexity and company_context.se_maturity_level == 'developing':
            score -= 0.2
            justification_parts.append("High complexity for developing maturity level")
            suggestions.append("Consider reducing complexity for developing SE maturity")
        elif not has_complexity and company_context.se_maturity_level == 'expert':
            score -= 0.1
            justification_parts.append("May be too simple for expert maturity level")
            suggestions.append("Consider increasing challenge for expert SE maturity")

        # Check resource availability
        if company_context.tools and any(tool.lower() in objective_text.lower() for tool in company_context.tools):
            score += 0.2
            justification_parts.append("References available company tools")
        else:
            suggestions.append("Ensure referenced tools are available to participants")

        # Check archetype alignment
        if archetype == 'Common basic understanding' and 'advanced' in objective_text.lower():
            score -= 0.2
            justification_parts.append("Advanced content may not fit basic understanding archetype")
            suggestions.append("Align complexity with 'basic understanding' archetype")

        justification = "; ".join(justification_parts)

        return SMARTScore(
            criterion="Achievable",
            score=min(max(score, 0.0), 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _validate_relevant(self, objective_text: str, competency: str, company_context: CompanyPMTContext, role: str) -> SMARTScore:
        """Validate Relevant criterion"""
        score = 0.0
        justification_parts = []
        suggestions = []

        # Check competency alignment
        if competency.lower() in objective_text.lower():
            score += 0.25
            justification_parts.append("Aligns with target competency")
        else:
            suggestions.append(f"Ensure alignment with {competency} competency")

        # Check industry relevance
        industry_terms = {
            'Automotive': ['vehicle', 'automotive', 'safety', 'iso 26262', 'driving'],
            'Aerospace': ['aircraft', 'flight', 'aviation', 'do-178', 'aerospace'],
            'Healthcare': ['medical', 'patient', 'clinical', 'fda', 'healthcare'],
            'Finance': ['financial', 'risk', 'trading', 'compliance', 'banking'],
            'Manufacturing': ['production', 'manufacturing', 'quality', 'lean', 'factory']
        }

        relevant_terms = industry_terms.get(company_context.industry_domain, [])
        has_industry_relevance = any(term in objective_text.lower() for term in relevant_terms)
        if has_industry_relevance:
            score += 0.25
            justification_parts.append("Industry-relevant content")
        else:
            suggestions.append(f"Include {company_context.industry_domain}-specific content")

        # Check role relevance
        if role and role.lower() in objective_text.lower():
            score += 0.25
            justification_parts.append("Relevant to target role")
        else:
            suggestions.append(f"Ensure relevance to {role} role")

        # Check business value
        business_terms = ['improve', 'efficiency', 'quality', 'reduce', 'optimize', 'enhance', 'deliver']
        has_business_value = any(term in objective_text.lower() for term in business_terms)
        if has_business_value:
            score += 0.25
            justification_parts.append("Addresses business value")
        else:
            suggestions.append("Include clear business value or benefit")

        justification = "; ".join(justification_parts) if justification_parts else "Limited relevance demonstrated"

        return SMARTScore(
            criterion="Relevant",
            score=min(score, 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _validate_time_bound(self, objective_text: str, archetype: str) -> SMARTScore:
        """Validate Time-bound criterion"""
        score = 0.0
        justification_parts = []
        suggestions = []

        # Check for explicit timeframes
        time_patterns = [
            r'\d+\s*(?:hours?|days?|weeks?|months?)',  # "2 weeks", "4 hours"
            r'at\s+the\s+end\s+of',  # "at the end of"
            r'after\s+\d+',  # "after 3 weeks"
            r'within\s+\d+',  # "within 2 months"
            r'by\s+the\s+end',  # "by the end"
        ]

        has_timeframe = any(re.search(pattern, objective_text, re.IGNORECASE) for pattern in time_patterns)
        if has_timeframe:
            score += 0.6
            justification_parts.append("Contains explicit timeframe")
        else:
            suggestions.append("Add specific timeframe (hours, days, weeks, months)")

        # Check for reasonable timeframe based on archetype
        archetype_timeframes = {
            'Common basic understanding': ['hours', 'day'],
            'Needs-based, project-oriented training': ['weeks', 'month'],
            'Train the trainer': ['months']
        }

        expected_timeframes = archetype_timeframes.get(archetype, ['weeks'])
        has_appropriate_timeframe = any(
            timeframe in objective_text.lower()
            for timeframe in expected_timeframes
        )

        if has_appropriate_timeframe:
            score += 0.4
            justification_parts.append("Timeframe appropriate for archetype")
        elif has_timeframe:
            justification_parts.append("Timeframe may not match archetype expectations")
            suggestions.append(f"Consider timeframe appropriate for {archetype}")

        if not has_timeframe:
            justification_parts.append("No explicit timeframe specified")

        justification = "; ".join(justification_parts)

        return SMARTScore(
            criterion="Time-bound",
            score=min(score, 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _validate_company_alignment(self, objective_text: str, company_context: CompanyPMTContext) -> SMARTScore:
        """Validate alignment with company PMT context"""
        score = 0.0
        justification_parts = []
        suggestions = []

        # Check for company-specific processes
        process_matches = sum(1 for proc in company_context.processes if proc.lower() in objective_text.lower())
        if process_matches > 0:
            score += min(0.3, process_matches * 0.15)
            justification_parts.append(f"References {process_matches} company processes")
        else:
            suggestions.append("Include company-specific processes")

        # Check for company-specific tools
        tool_matches = sum(1 for tool in company_context.tools if tool.lower() in objective_text.lower())
        if tool_matches > 0:
            score += min(0.3, tool_matches * 0.15)
            justification_parts.append(f"References {tool_matches} company tools")
        else:
            suggestions.append("Include company-specific tools")

        # Check for company challenges
        challenge_matches = sum(1 for challenge in company_context.current_challenges if any(word in objective_text.lower() for word in challenge.lower().split()))
        if challenge_matches > 0:
            score += min(0.4, challenge_matches * 0.2)
            justification_parts.append(f"Addresses {challenge_matches} company challenges")
        else:
            suggestions.append("Address specific company challenges")

        justification = "; ".join(justification_parts) if justification_parts else "Limited company-specific context"

        return SMARTScore(
            criterion="Company Alignment",
            score=min(score, 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _validate_incose_compliance(self, objective_text: str, competency: str) -> SMARTScore:
        """Validate alignment with INCOSE SE competency framework"""
        score = 0.7  # Base score assuming general alignment
        justification_parts = ["General alignment with SE principles"]
        suggestions = []

        # INCOSE competency keywords
        incose_terms = {
            'systemic thinking': ['system', 'holistic', 'emergent', 'boundary', 'interface'],
            'requirements management': ['requirements', 'stakeholder', 'elicitation', 'traceability'],
            'system architecture': ['architecture', 'design', 'structure', 'pattern', 'interface'],
            'technical leadership': ['leadership', 'decision', 'guidance', 'strategy', 'innovation'],
            'integration': ['integration', 'interface', 'interoperability', 'testing']
        }

        competency_key = competency.lower()
        if competency_key in incose_terms:
            relevant_terms = incose_terms[competency_key]
            term_matches = sum(1 for term in relevant_terms if term in objective_text.lower())
            if term_matches >= 2:
                score += 0.3
                justification_parts.append(f"Strong INCOSE competency alignment ({term_matches} relevant terms)")
            elif term_matches >= 1:
                score += 0.15
                justification_parts.append(f"Moderate INCOSE competency alignment ({term_matches} relevant terms)")
            else:
                suggestions.append(f"Include INCOSE-relevant terms for {competency}")

        justification = "; ".join(justification_parts)

        return SMARTScore(
            criterion="INCOSE Compliance",
            score=min(score, 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _validate_business_value(self, objective_text: str, company_context: CompanyPMTContext) -> SMARTScore:
        """Validate clear business value proposition"""
        score = 0.0
        justification_parts = []
        suggestions = []

        # Check for "so that" business benefit clause
        if "so that" in objective_text.lower():
            score += 0.4
            justification_parts.append("Includes explicit business benefit")
        else:
            suggestions.append("Add 'so that' clause explaining business benefit")

        # Check for value-oriented language
        value_terms = ['improve', 'reduce', 'enhance', 'optimize', 'increase', 'deliver', 'ensure', 'enable']
        value_matches = sum(1 for term in value_terms if term in objective_text.lower())
        if value_matches > 0:
            score += min(0.3, value_matches * 0.1)
            justification_parts.append(f"Contains {value_matches} value-oriented terms")
        else:
            suggestions.append("Include value-oriented language (improve, reduce, enable, etc.)")

        # Check for business outcomes
        business_outcomes = ['efficiency', 'quality', 'compliance', 'safety', 'performance', 'cost', 'risk']
        outcome_matches = sum(1 for outcome in business_outcomes if outcome in objective_text.lower())
        if outcome_matches > 0:
            score += min(0.3, outcome_matches * 0.15)
            justification_parts.append(f"Addresses {outcome_matches} business outcomes")
        else:
            suggestions.append("Specify concrete business outcomes")

        justification = "; ".join(justification_parts) if justification_parts else "Limited business value articulation"

        return SMARTScore(
            criterion="Business Value",
            score=min(score, 1.0),
            justification=justification,
            improvement_suggestions=suggestions
        )

    def _generate_recommendations(self, assessment: QualityAssessment):
        """Generate strengths, weaknesses, and improvement recommendations"""

        # Identify strengths (scores >= 0.8)
        all_scores = [
            assessment.specific_score,
            assessment.measurable_score,
            assessment.achievable_score,
            assessment.relevant_score,
            assessment.time_bound_score,
            assessment.company_alignment_score,
            assessment.incose_compliance_score,
            assessment.business_value_score
        ]

        for score in all_scores:
            if score.score >= 0.8:
                assessment.strengths.append(f"{score.criterion}: {score.justification}")
            elif score.score < 0.6:
                assessment.weaknesses.append(f"{score.criterion}: {score.justification}")

        # Generate improvement plan from suggestions
        for score in all_scores:
            if score.improvement_suggestions:
                assessment.improvement_plan.extend(score.improvement_suggestions)

        # Remove duplicates
        assessment.improvement_plan = list(set(assessment.improvement_plan))

    def _initialize_validation_patterns(self) -> Dict[str, List[str]]:
        """Initialize validation patterns for criteria"""
        return {
            'action_verbs': ['understand', 'apply', 'analyze', 'create', 'evaluate', 'demonstrate'],
            'measurable_verbs': ['demonstrate', 'identify', 'create', 'analyze', 'implement'],
            'time_indicators': ['hours', 'days', 'weeks', 'months', 'at the end', 'within', 'by'],
            'business_value': ['improve', 'reduce', 'enhance', 'optimize', 'ensure', 'enable']
        }

    def _initialize_scoring_criteria(self) -> Dict[str, Dict[str, float]]:
        """Initialize scoring criteria weights"""
        return {
            'smart_weights': {
                'specific': 0.2,
                'measurable': 0.2,
                'achievable': 0.2,
                'relevant': 0.2,
                'time_bound': 0.2
            },
            'overall_weights': {
                'smart': 0.6,
                'company_alignment': 0.2,
                'incose_compliance': 0.1,
                'business_value': 0.1
            }
        }

    def _get_default_assessment(self, objective_text: str, competency: str) -> QualityAssessment:
        """Get default assessment when validation fails"""
        default_score = SMARTScore("Default", 0.5, "Error in validation", [])

        return QualityAssessment(
            objective_text=objective_text,
            competency=competency,
            company_context="Unknown",
            specific_score=default_score,
            measurable_score=default_score,
            achievable_score=default_score,
            relevant_score=default_score,
            time_bound_score=default_score,
            company_alignment_score=default_score,
            incose_compliance_score=default_score,
            business_value_score=default_score
        )

    def save_assessment(self, assessment: QualityAssessment, filepath: str):
        """Save assessment to JSON file"""
        try:
            with open(filepath, 'w') as f:
                json.dump(asdict(assessment), f, indent=2)
            logger.info(f"Assessment saved to {filepath}")
        except Exception as e:
            logger.error(f"Error saving assessment: {e}")

def main():
    """Test the SMART validation system"""
    from company_context_extractor import CompanyPMTContext

    validator = SMARTValidator(quality_threshold=0.85)

    # Test company context
    test_context = CompanyPMTContext(
        company_name="AutoTech Systems",
        industry_domain="Automotive",
        business_domain="Autonomous Vehicles",
        processes=["Requirements Engineering", "Functional Safety", "V&V"],
        methods=["V-Model", "Agile", "ISO 26262"],
        tools=["DOORS", "MATLAB/Simulink", "Jenkins"],
        se_maturity_level="developing",
        current_challenges=["Autonomous driving certification", "Sensor integration"],
        organizational_size="large"
    )

    # Test objectives with different quality levels
    test_objectives = [
        {
            'text': "At the end of 2 weeks, participants will be able to identify system boundaries and interfaces in AutoTech Systems' autonomous vehicle architecture by analyzing system models using DOORS so that sensor integration challenges are better understood.",
            'competency': "Systemic thinking",
            'archetype': "Needs-based, project-oriented training",
            'role': "System engineer"
        },
        {
            'text': "Participants will understand systems.",
            'competency': "Systemic thinking",
            'archetype': "Common basic understanding",
            'role': "Engineer"
        },
        {
            'text': "At the end of 4 hours, participants will demonstrate understanding of Requirements Engineering principles by creating requirement specifications using DOORS templates so that AutoTech Systems can improve autonomous driving certification processes.",
            'competency': "Requirements management",
            'archetype': "Common basic understanding",
            'role': "Requirements engineer"
        }
    ]

    for i, obj in enumerate(test_objectives):
        print(f"\\n=== Test Objective {i+1} ===")
        print(f"Text: {obj['text']}")

        assessment = validator.validate_objective(
            objective_text=obj['text'],
            competency=obj['competency'],
            company_context=test_context,
            archetype=obj['archetype'],
            role=obj['role']
        )

        print(f"\\nQuality Assessment:")
        print(f"SMART Average: {assessment.smart_average:.2f}")
        print(f"Overall Quality: {assessment.overall_quality:.2f}")
        print(f"Meets Threshold (>=85%): {assessment.meets_threshold}")

        print(f"\\nIndividual Scores:")
        print(f"  Specific: {assessment.specific_score.score:.2f} - {assessment.specific_score.justification}")
        print(f"  Measurable: {assessment.measurable_score.score:.2f} - {assessment.measurable_score.justification}")
        print(f"  Achievable: {assessment.achievable_score.score:.2f} - {assessment.achievable_score.justification}")
        print(f"  Relevant: {assessment.relevant_score.score:.2f} - {assessment.relevant_score.justification}")
        print(f"  Time-bound: {assessment.time_bound_score.score:.2f} - {assessment.time_bound_score.justification}")

        print(f"\\nAdditional Criteria:")
        print(f"  Company Alignment: {assessment.company_alignment_score.score:.2f}")
        print(f"  INCOSE Compliance: {assessment.incose_compliance_score.score:.2f}")
        print(f"  Business Value: {assessment.business_value_score.score:.2f}")

        if assessment.strengths:
            print(f"\\nStrengths: {assessment.strengths}")
        if assessment.weaknesses:
            print(f"\\nWeaknesses: {assessment.weaknesses}")
        if assessment.improvement_plan:
            print(f"\\nImprovement Plan: {assessment.improvement_plan[:3]}")  # Show first 3

        # Save assessment
        validator.save_assessment(assessment, f"test_assessment_{i+1}.json")

if __name__ == "__main__":
    main()