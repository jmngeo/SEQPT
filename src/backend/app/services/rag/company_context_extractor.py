"""
Company PMT (Processes, Methods, Tools) Context Extraction System
Extracts and structures company-specific context for RAG-LLM generation
"""

import os
import json
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime
from dataclasses import dataclass, asdict
from pydantic import BaseModel, Field

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class CompanyPMTContext:
    """Company Processes, Methods, Tools context model"""
    company_name: str
    industry_domain: str
    business_domain: str = ""

    # PMT Framework Components
    processes: List[str] = None
    methods: List[str] = None
    tools: List[str] = None

    # SE-specific context
    se_maturity_level: str = "developing"  # developing, established, advanced, expert
    current_challenges: List[str] = None
    organizational_size: str = "medium"  # small, medium, large, enterprise

    # Project context
    typical_project_types: List[str] = None
    regulatory_requirements: List[str] = None

    # Qualification context
    learning_preferences: List[str] = None
    available_resources: Dict[str, str] = None

    def __post_init__(self):
        if self.processes is None:
            self.processes = []
        if self.methods is None:
            self.methods = []
        if self.tools is None:
            self.tools = []
        if self.current_challenges is None:
            self.current_challenges = []
        if self.typical_project_types is None:
            self.typical_project_types = []
        if self.regulatory_requirements is None:
            self.regulatory_requirements = []
        if self.learning_preferences is None:
            self.learning_preferences = []
        if self.available_resources is None:
            self.available_resources = {}

class CompanyContextExtractor:
    """Extracts and structures company PMT context for RAG generation"""

    def __init__(self):
        self.industry_templates = self._load_industry_templates()
        self.se_process_catalog = self._load_se_process_catalog()
        self.tools_catalog = self._load_tools_catalog()
        logger.info("Company Context Extractor initialized")

    def extract_context_from_text(self, company_description: str, company_name: str = "Unknown") -> CompanyPMTContext:
        """Extract PMT context from free-text company description"""
        try:
            # Basic extraction using keyword matching
            industry = self._extract_industry(company_description)
            processes = self._extract_processes(company_description)
            methods = self._extract_methods(company_description)
            tools = self._extract_tools(company_description)
            challenges = self._extract_challenges(company_description)
            maturity = self._extract_maturity_level(company_description)

            context = CompanyPMTContext(
                company_name=company_name,
                industry_domain=industry,
                business_domain=self._extract_business_domain(company_description),
                processes=processes,
                methods=methods,
                tools=tools,
                se_maturity_level=maturity,
                current_challenges=challenges,
                organizational_size=self._extract_org_size(company_description),
                typical_project_types=self._extract_project_types(company_description),
                regulatory_requirements=self._extract_regulatory_requirements(company_description)
            )

            logger.info(f"Extracted context for {company_name} in {industry} domain")
            return context

        except Exception as e:
            logger.error(f"Error extracting context: {e}")
            return self._get_default_context(company_name)

    def create_context_from_questionnaire(self, questionnaire_data: Dict[str, Any]) -> CompanyPMTContext:
        """Create PMT context from structured questionnaire data"""
        try:
            context = CompanyPMTContext(
                company_name=questionnaire_data.get('company_name', 'Unknown'),
                industry_domain=questionnaire_data.get('industry', 'General'),
                business_domain=questionnaire_data.get('business_domain', ''),
                processes=questionnaire_data.get('processes', []),
                methods=questionnaire_data.get('methods', []),
                tools=questionnaire_data.get('tools', []),
                se_maturity_level=questionnaire_data.get('se_maturity', 'developing'),
                current_challenges=questionnaire_data.get('challenges', []),
                organizational_size=questionnaire_data.get('org_size', 'medium'),
                typical_project_types=questionnaire_data.get('project_types', []),
                regulatory_requirements=questionnaire_data.get('regulations', []),
                learning_preferences=questionnaire_data.get('learning_prefs', []),
                available_resources=questionnaire_data.get('resources', {})
            )

            logger.info(f"Created context from questionnaire for {context.company_name}")
            return context

        except Exception as e:
            logger.error(f"Error creating context from questionnaire: {e}")
            return self._get_default_context(questionnaire_data.get('company_name', 'Unknown'))

    def enrich_context_with_templates(self, context: CompanyPMTContext) -> CompanyPMTContext:
        """Enrich context using industry-specific templates"""
        try:
            industry_template = self.industry_templates.get(context.industry_domain.lower(), {})

            # Enhance processes
            template_processes = industry_template.get('common_processes', [])
            context.processes.extend([p for p in template_processes if p not in context.processes])

            # Enhance methods
            template_methods = industry_template.get('common_methods', [])
            context.methods.extend([m for m in template_methods if m not in context.methods])

            # Enhance tools
            template_tools = industry_template.get('common_tools', [])
            context.tools.extend([t for t in template_tools if t not in context.tools])

            # Add industry-specific challenges
            template_challenges = industry_template.get('common_challenges', [])
            context.current_challenges.extend([c for c in template_challenges if c not in context.current_challenges])

            logger.info(f"Enriched context for {context.company_name} using {context.industry_domain} template")
            return context

        except Exception as e:
            logger.error(f"Error enriching context: {e}")
            return context

    def generate_context_summary(self, context: CompanyPMTContext) -> str:
        """Generate human-readable context summary for RAG prompts"""
        summary_parts = [
            f"Company: {context.company_name}",
            f"Industry: {context.industry_domain}",
            f"SE Maturity: {context.se_maturity_level}",
        ]

        if context.processes:
            summary_parts.append(f"Key Processes: {', '.join(context.processes[:5])}")

        if context.methods:
            summary_parts.append(f"Methods Used: {', '.join(context.methods[:5])}")

        if context.tools:
            summary_parts.append(f"Tools/Technologies: {', '.join(context.tools[:5])}")

        if context.current_challenges:
            summary_parts.append(f"Current Challenges: {', '.join(context.current_challenges[:3])}")

        return ". ".join(summary_parts) + "."

    def _extract_industry(self, text: str) -> str:
        """Extract industry from text description"""
        text_lower = text.lower()

        industry_keywords = {
            'automotive': ['automotive', 'car', 'vehicle', 'automobile', 'mobility'],
            'aerospace': ['aerospace', 'aviation', 'aircraft', 'flight', 'satellite'],
            'healthcare': ['healthcare', 'medical', 'pharma', 'hospital', 'clinical', 'device', 'cardiac', 'fda'],
            'finance': ['finance', 'bank', 'investment', 'trading', 'fintech'],
            'manufacturing': ['manufacturing', 'production', 'factory', 'industrial'],
            'telecommunications': ['telecom', 'network', 'communication', '5g', 'wireless'],
            'energy': ['energy', 'power', 'renewable', 'grid', 'utility'],
            'defense': ['defense', 'military', 'security', 'surveillance'],
            'software': ['software', 'tech', 'digital', 'platform', 'saas']
        }

        for industry, keywords in industry_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                return industry.title()

        return "General"

    def _extract_processes(self, text: str) -> List[str]:
        """Extract SE processes from text"""
        text_lower = text.lower()
        found_processes = []

        process_keywords = {
            'Requirements Engineering': ['requirements', 'requirement', 'specs', 'specification'],
            'System Architecture': ['architecture', 'design', 'structure', 'architectural'],
            'Configuration Management': ['configuration', 'version control', 'change management'],
            'Verification & Validation': ['verification', 'validation', 'testing', 'v&v'],
            'Risk Management': ['risk', 'safety', 'hazard', 'mitigation'],
            'Project Management': ['project', 'planning', 'management', 'coordination'],
            'Quality Assurance': ['quality', 'qms', 'iso', 'compliance'],
            'Integration': ['integration', 'interfaces', 'interoperability']
        }

        for process, keywords in process_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                found_processes.append(process)

        return found_processes

    def _extract_methods(self, text: str) -> List[str]:
        """Extract SE methods from text"""
        text_lower = text.lower()
        found_methods = []

        method_keywords = {
            'Agile': ['agile', 'scrum', 'sprint', 'kanban'],
            'V-Model': ['v-model', 'vmodel', 'waterfall'],
            'DevOps': ['devops', 'ci/cd', 'continuous'],
            'Model-Based Systems Engineering': ['mbse', 'model-based', 'sysml'],
            'Lean': ['lean', 'waste reduction', 'efficiency'],
            'Six Sigma': ['six sigma', 'dmaic', 'quality improvement']
        }

        for method, keywords in method_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                found_methods.append(method)

        return found_methods

    def _extract_tools(self, text: str) -> List[str]:
        """Extract tools and technologies from text"""
        text_lower = text.lower()
        found_tools = []

        tool_keywords = {
            'DOORS': ['doors', 'ibm doors'],
            'JIRA': ['jira', 'atlassian'],
            'MATLAB/Simulink': ['matlab', 'simulink'],
            'Enterprise Architect': ['enterprise architect', 'sparx'],
            'Git': ['git', 'github', 'gitlab'],
            'Jenkins': ['jenkins', 'ci/cd'],
            'Docker': ['docker', 'containers'],
            'Kubernetes': ['kubernetes', 'k8s'],
            'AWS/Azure/GCP': ['aws', 'azure', 'gcp', 'cloud'],
            'SysML': ['sysml', 'uml', 'modeling']
        }

        for tool, keywords in tool_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                found_tools.append(tool)

        return found_tools

    def _extract_challenges(self, text: str) -> List[str]:
        """Extract current challenges from text"""
        text_lower = text.lower()
        found_challenges = []

        challenge_keywords = {
            'Complex system integration': ['integration', 'complexity', 'interfaces'],
            'Regulatory compliance': ['regulation', 'compliance', 'certification'],
            'Rapid technology change': ['technology change', 'innovation', 'disruption'],
            'Resource constraints': ['resource', 'budget', 'timeline'],
            'Skills gap': ['skills', 'training', 'competency', 'knowledge'],
            'Quality assurance': ['quality', 'defects', 'reliability'],
            'Digital transformation': ['digital', 'transformation', 'modernization']
        }

        for challenge, keywords in challenge_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                found_challenges.append(challenge)

        return found_challenges

    def _extract_maturity_level(self, text: str) -> str:
        """Extract SE maturity level from text"""
        text_lower = text.lower()

        if any(word in text_lower for word in ['expert', 'advanced', 'mature', 'sophisticated']):
            return 'expert'
        elif any(word in text_lower for word in ['established', 'experienced', 'proven']):
            return 'established'
        elif any(word in text_lower for word in ['developing', 'growing', 'improving']):
            return 'developing'
        else:
            return 'developing'

    def _extract_business_domain(self, text: str) -> str:
        """Extract specific business domain"""
        text_lower = text.lower()

        if 'autonomous' in text_lower or 'self-driving' in text_lower:
            return 'Autonomous Systems'
        elif 'iot' in text_lower or 'internet of things' in text_lower:
            return 'IoT Systems'
        elif 'medical device' in text_lower:
            return 'Medical Devices'
        elif 'fintech' in text_lower:
            return 'Financial Technology'
        else:
            return 'General Systems'

    def _extract_org_size(self, text: str) -> str:
        """Extract organization size"""
        text_lower = text.lower()

        if any(word in text_lower for word in ['startup', 'small', 'sme']):
            return 'small'
        elif any(word in text_lower for word in ['enterprise', 'corporation', 'multinational']):
            return 'enterprise'
        elif 'large' in text_lower:
            return 'large'
        else:
            return 'medium'

    def _extract_project_types(self, text: str) -> List[str]:
        """Extract typical project types"""
        text_lower = text.lower()
        found_types = []

        type_keywords = {
            'New product development': ['new product', 'development', 'innovation'],
            'Legacy system modernization': ['legacy', 'modernization', 'upgrade'],
            'System integration': ['integration', 'interfaces'],
            'Compliance projects': ['compliance', 'regulatory', 'certification'],
            'Digital transformation': ['digital', 'transformation']
        }

        for proj_type, keywords in type_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                found_types.append(proj_type)

        return found_types

    def _extract_regulatory_requirements(self, text: str) -> List[str]:
        """Extract regulatory requirements"""
        text_lower = text.lower()
        found_reqs = []

        regulatory_keywords = {
            'ISO 26262': ['iso 26262', 'functional safety', 'automotive safety'],
            'FDA': ['fda', 'medical device'],
            'DO-178C': ['do-178', 'aviation software'],
            'IEC 61508': ['iec 61508', 'functional safety'],
            'GDPR': ['gdpr', 'data protection'],
            'SOX': ['sox', 'sarbanes'],
            'HIPAA': ['hipaa', 'healthcare']
        }

        for regulation, keywords in regulatory_keywords.items():
            if any(keyword in text_lower for keyword in keywords):
                found_reqs.append(regulation)

        return found_reqs

    def _load_industry_templates(self) -> Dict[str, Dict]:
        """Load industry-specific context templates"""
        return {
            'automotive': {
                'common_processes': ['Requirements Engineering', 'Functional Safety', 'V&V', 'SPICE'],
                'common_methods': ['V-Model', 'Agile', 'Functional Safety'],
                'common_tools': ['DOORS', 'MATLAB/Simulink', 'PTC Integrity'],
                'common_challenges': ['ISO 26262 compliance', 'Autonomous driving', 'Electrification']
            },
            'aerospace': {
                'common_processes': ['Requirements Engineering', 'Configuration Management', 'V&V'],
                'common_methods': ['V-Model', 'MBSE', 'DO-178C'],
                'common_tools': ['DOORS', 'Enterprise Architect', 'MATLAB'],
                'common_challenges': ['DO-178C compliance', 'Weight constraints', 'Certification']
            },
            'healthcare': {
                'common_processes': ['Requirements Engineering', 'Risk Management', 'Quality Assurance'],
                'common_methods': ['V-Model', 'Risk Management', 'FDA Process'],
                'common_tools': ['DOORS', 'MedDRA', 'Clinical Trial Systems'],
                'common_challenges': ['FDA approval', 'Patient safety', 'Clinical validation']
            }
        }

    def _load_se_process_catalog(self) -> List[str]:
        """Load catalog of SE processes"""
        return [
            'Business or Mission Analysis',
            'Stakeholder Needs and Requirements Definition',
            'System Requirements Definition',
            'Architecture Definition',
            'Design Definition',
            'System Analysis',
            'Implementation',
            'Integration',
            'Verification',
            'Validation',
            'Transition',
            'Operation',
            'Maintenance',
            'Disposal'
        ]

    def _load_tools_catalog(self) -> List[str]:
        """Load catalog of common SE tools"""
        return [
            'DOORS', 'JIRA', 'MATLAB/Simulink', 'Enterprise Architect',
            'Git', 'Jenkins', 'Docker', 'Kubernetes', 'AWS', 'Azure',
            'SysML', 'UML', 'Cameo Systems Modeler', 'MagicDraw',
            'PTC Integrity', 'Polarion', 'Teamcenter', 'Windchill'
        ]

    def _get_default_context(self, company_name: str) -> CompanyPMTContext:
        """Get default context when extraction fails"""
        return CompanyPMTContext(
            company_name=company_name,
            industry_domain="General",
            business_domain="General Systems",
            processes=["Requirements Engineering", "System Architecture", "Integration"],
            methods=["Agile", "V-Model"],
            tools=["JIRA", "Git"],
            se_maturity_level="developing",
            current_challenges=["Resource constraints", "Quality assurance"],
            organizational_size="medium"
        )

    def save_context(self, context: CompanyPMTContext, filepath: str):
        """Save context to JSON file"""
        try:
            with open(filepath, 'w') as f:
                json.dump(asdict(context), f, indent=2)
            logger.info(f"Context saved to {filepath}")
        except Exception as e:
            logger.error(f"Error saving context: {e}")

    def load_context(self, filepath: str) -> Optional[CompanyPMTContext]:
        """Load context from JSON file"""
        try:
            with open(filepath, 'r') as f:
                data = json.load(f)
            context = CompanyPMTContext(**data)
            logger.info(f"Context loaded from {filepath}")
            return context
        except Exception as e:
            logger.error(f"Error loading context: {e}")
            return None

def main():
    """Test the context extraction system"""
    extractor = CompanyContextExtractor()

    # Test with example company descriptions
    test_cases = [
        {
            'name': 'AutoTech Motors',
            'description': 'AutoTech Motors is an automotive OEM developing autonomous vehicles. We use MATLAB/Simulink for modeling, DOORS for requirements management, and follow ISO 26262 for functional safety. Our main challenges include complex sensor integration and safety certification for self-driving features.'
        },
        {
            'name': 'AeroSpace Systems',
            'description': 'AeroSpace Systems develops avionics software for commercial aircraft. We follow DO-178C standards and use Enterprise Architect for system modeling. Our main focus is on flight management systems and we work with Boeing and Airbus.'
        },
        {
            'name': 'MedDevice Corp',
            'description': 'MedDevice Corp creates medical devices for cardiac monitoring. We must comply with FDA regulations and follow IEC 62304 for medical device software. Our main challenges are clinical validation and regulatory approval processes.'
        }
    ]

    for test_case in test_cases:
        print(f"\n=== Testing {test_case['name']} ===")

        # Extract context
        context = extractor.extract_context_from_text(
            test_case['description'],
            test_case['name']
        )

        # Enrich with templates
        enriched_context = extractor.enrich_context_with_templates(context)

        # Generate summary
        summary = extractor.generate_context_summary(enriched_context)

        print(f"Industry: {enriched_context.industry_domain}")
        print(f"Processes: {enriched_context.processes}")
        print(f"Methods: {enriched_context.methods}")
        print(f"Tools: {enriched_context.tools}")
        print(f"Challenges: {enriched_context.current_challenges}")
        print(f"Maturity: {enriched_context.se_maturity_level}")
        print(f"Summary: {summary}")

        # Save context
        extractor.save_context(enriched_context, f"{test_case['name'].lower().replace(' ', '_')}_context.json")

if __name__ == "__main__":
    main()