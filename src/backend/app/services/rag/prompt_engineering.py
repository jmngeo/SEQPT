"""
Objective Customization Prompt Engineering System
Core innovation for RAG-LLM learning objective generation
"""

import os
import json
import logging
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
from dataclasses import dataclass
from company_context_extractor import CompanyPMTContext

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class PromptTemplate:
    """Template for different types of prompts"""
    name: str
    system_prompt: str
    human_prompt: str
    variables: List[str]
    archetype_specific: bool = False
    competency_specific: bool = False

class ObjectivePromptEngineer:
    """Advanced prompt engineering for company-specific learning objectives"""

    def __init__(self):
        self.base_templates = self._initialize_base_templates()
        self.archetype_templates = self._initialize_archetype_templates()
        self.competency_templates = self._initialize_competency_templates()
        self.quality_criteria = self._initialize_quality_criteria()
        logger.info("Objective Prompt Engineer initialized")

    def generate_customized_prompt(
        self,
        competency: str,
        role: str,
        archetype: str,
        company_context: CompanyPMTContext,
        template_context: str = "",
        additional_requirements: List[str] = None
    ) -> Tuple[str, str]:
        """Generate customized system and human prompts for RAG-LLM"""

        # Select appropriate templates
        system_template = self._select_system_template(archetype, competency)
        human_template = self._select_human_template(archetype, competency)

        # Generate context-aware prompts
        system_prompt = self._generate_system_prompt(
            system_template, competency, role, archetype, company_context
        )

        human_prompt = self._generate_human_prompt(
            human_template, competency, role, archetype,
            company_context, template_context, additional_requirements
        )

        logger.info(f"Generated customized prompt for {competency} in {archetype} archetype")
        return system_prompt, human_prompt

    def _select_system_template(self, archetype: str, competency: str) -> PromptTemplate:
        """Select most appropriate system template"""
        # Try archetype-specific template first
        archetype_key = archetype.lower().replace(" ", "_").replace(",", "")
        if archetype_key in self.archetype_templates:
            return self.archetype_templates[archetype_key]['system']

        # Try competency-specific template
        competency_key = competency.lower().replace(" ", "_")
        if competency_key in self.competency_templates:
            return self.competency_templates[competency_key]['system']

        # Fall back to base template
        return self.base_templates['system']

    def _select_human_template(self, archetype: str, competency: str) -> PromptTemplate:
        """Select most appropriate human template"""
        # Try archetype-specific template first
        archetype_key = archetype.lower().replace(" ", "_").replace(",", "")
        if archetype_key in self.archetype_templates:
            return self.archetype_templates[archetype_key]['human']

        # Try competency-specific template
        competency_key = competency.lower().replace(" ", "_")
        if competency_key in self.competency_templates:
            return self.competency_templates[competency_key]['human']

        # Fall back to base template
        return self.base_templates['human']

    def _generate_system_prompt(
        self,
        template: PromptTemplate,
        competency: str,
        role: str,
        archetype: str,
        company_context: CompanyPMTContext
    ) -> str:
        """Generate customized system prompt"""

        # Get industry-specific expertise
        industry_expertise = self._get_industry_expertise(company_context.industry_domain)

        # Get archetype-specific guidance
        archetype_guidance = self._get_archetype_guidance(archetype)

        # Get competency-specific focus
        competency_focus = self._get_competency_focus(competency)

        # Format the system prompt
        system_prompt = template.system_prompt.format(
            competency=competency,
            role=role,
            archetype=archetype,
            industry=company_context.industry_domain,
            company_name=company_context.company_name,
            se_maturity=company_context.se_maturity_level,
            industry_expertise=industry_expertise,
            archetype_guidance=archetype_guidance,
            competency_focus=competency_focus,
            quality_criteria=self._format_quality_criteria()
        )

        return system_prompt

    def _generate_human_prompt(
        self,
        template: PromptTemplate,
        competency: str,
        role: str,
        archetype: str,
        company_context: CompanyPMTContext,
        template_context: str,
        additional_requirements: List[str] = None
    ) -> str:
        """Generate customized human prompt"""

        # Format company context
        context_summary = self._format_company_context(company_context)

        # Format PMT details
        pmt_details = self._format_pmt_details(company_context)

        # Format additional requirements
        additional_reqs = ""
        if additional_requirements:
            additional_reqs = "\\n".join([f"- {req}" for req in additional_requirements])

        # Format the human prompt
        human_prompt = template.human_prompt.format(
            competency=competency,
            role=role,
            archetype=archetype,
            company_name=company_context.company_name,
            industry=company_context.industry_domain,
            business_domain=company_context.business_domain,
            context_summary=context_summary,
            pmt_details=pmt_details,
            processes=", ".join(company_context.processes[:5]),
            methods=", ".join(company_context.methods[:5]),
            tools=", ".join(company_context.tools[:5]),
            challenges=", ".join(company_context.current_challenges[:3]),
            se_maturity=company_context.se_maturity_level,
            org_size=company_context.organizational_size,
            template_context=template_context,
            additional_requirements=additional_reqs,
            learning_format_guidance=self._get_learning_format_guidance(archetype),
            timeframe_guidance=self._get_timeframe_guidance(archetype, company_context.se_maturity_level)
        )

        return human_prompt

    def _initialize_base_templates(self) -> Dict[str, PromptTemplate]:
        """Initialize base prompt templates"""
        return {
            'system': PromptTemplate(
                name="base_system",
                system_prompt="""You are an expert Systems Engineering learning objective designer with deep expertise in {industry} industry and {se_maturity} SE organizations.

Your specialization includes:
{industry_expertise}

Your task is to generate company-specific learning objectives that are:
1. SMART (Specific, Measurable, Achievable, Relevant, Time-bound)
2. Tailored to {company_name}'s specific context, processes, methods, and tools
3. Aligned with INCOSE SE competency framework for {competency}
4. Appropriate for {archetype} qualification strategy
5. Practical and actionable for {role} role

{archetype_guidance}

{competency_focus}

Quality Criteria:
{quality_criteria}

Generate objectives that demonstrate deep understanding of the company's specific context and challenges.""",
                human_prompt="",
                variables=["competency", "role", "archetype", "industry", "company_name", "se_maturity"]
            ),
            'human': PromptTemplate(
                name="base_human",
                system_prompt="",
                human_prompt="""Create a company-specific learning objective for:

COMPETENCY: {competency}
ROLE: {role}
QUALIFICATION ARCHETYPE: {archetype}

COMPANY CONTEXT:
{context_summary}

SPECIFIC PMT CONTEXT:
{pmt_details}

TEMPLATE EXAMPLES (for inspiration):
{template_context}

REQUIREMENTS:
- Use company-specific processes: {processes}
- Incorporate methods: {methods}
- Reference tools/technologies: {tools}
- Address current challenges: {challenges}
- Consider SE maturity level: {se_maturity}
- Fit organization size: {org_size}

{learning_format_guidance}

{timeframe_guidance}

{additional_requirements}

Generate ONE specific, actionable learning objective using this format:
"At the end of [timeframe], participants will be able to [specific measurable outcome] by [method/approach using company tools] so that [business benefit addressing company challenges]."

Ensure the objective:
1. Uses {company_name}'s specific processes, methods, and tools
2. Addresses their actual challenges in {industry}
3. Fits the {archetype} strategy
4. Is measurable and observable
5. Includes realistic timeframe
6. Provides clear business value

Learning Objective:""",
                variables=["competency", "role", "archetype", "company_name", "industry", "business_domain"]
            )
        }

    def _initialize_archetype_templates(self) -> Dict[str, Dict[str, PromptTemplate]]:
        """Initialize archetype-specific templates"""
        return {
            'common_basic_understanding': {
                'system': PromptTemplate(
                    name="common_basic_system",
                    system_prompt="""You are designing foundational learning objectives for "Common basic understanding" archetype.

Focus on:
- Broad awareness and basic comprehension
- Fundamental concepts and principles
- Common vocabulary and terminology
- Basic application in simple scenarios
- Foundation for further learning

Format: Workshop-style, interactive learning with practical examples from {company_name}'s context.""",
                    human_prompt="",
                    variables=[]
                ),
                'human': PromptTemplate(
                    name="common_basic_human",
                    system_prompt="",
                    human_prompt="""Create a foundational learning objective that provides basic understanding of {competency} for {role} role.

Focus on fundamental concepts that apply across {company_name}'s operations.
Use workshop format (2-4 hours) with interactive exercises.
Ensure broad applicability across different teams and projects.

The objective should build foundational knowledge that enables further specialized training.""",
                    variables=[]
                )
            },
            'needs-based_project-oriented_training': {
                'system': PromptTemplate(
                    name="project_oriented_system",
                    system_prompt="""You are designing practical, project-focused learning objectives for "Needs-based, project-oriented training" archetype.

Focus on:
- Real project application and immediate use
- Hands-on practice with actual tools and processes
- Problem-solving in authentic work context
- Measurable project outcomes
- Just-in-time learning aligned with project needs

Format: On-the-job training, mentoring, or project-based workshops.""",
                    human_prompt="",
                    variables=[]
                ),
                'human': PromptTemplate(
                    name="project_oriented_human",
                    system_prompt="",
                    human_prompt="""Create a project-oriented learning objective that enables immediate application of {competency} in {company_name}'s current projects.

Focus on:
- Specific project deliverables and outcomes
- Hands-on use of their tools: {tools}
- Addressing their current challenges: {challenges}
- Measurable project impact

The objective should enable participants to contribute effectively to ongoing projects immediately after training.

Use on-the-job training or mentoring format (2-4 weeks duration).""",
                    variables=[]
                )
            },
            'train_the_trainer': {
                'system': PromptTemplate(
                    name="train_trainer_system",
                    system_prompt="""You are designing advanced learning objectives for "Train the trainer" archetype.

Focus on:
- Mastery-level competency demonstration
- Teaching and mentoring capabilities
- Creation of learning materials and methods
- Assessment and evaluation skills
- Leadership in competency development

Format: Advanced certification programs, mentoring assignments, teaching responsibilities.""",
                    human_prompt="",
                    variables=[]
                ),
                'human': PromptTemplate(
                    name="train_trainer_human",
                    system_prompt="",
                    human_prompt="""Create an advanced learning objective that develops {competency} expertise to trainer/mentor level.

The participant should be able to:
- Demonstrate mastery in {company_name}'s context
- Teach and mentor others effectively
- Create learning materials and assessments
- Lead competency development initiatives

Use certification program format (3-6 months) with teaching assignments and mentoring responsibilities.

Focus on developing internal expertise and capability to scale learning across the organization.""",
                    variables=[]
                )
            }
        }

    def _initialize_competency_templates(self) -> Dict[str, Dict[str, PromptTemplate]]:
        """Initialize competency-specific templates"""
        return {
            'systemic_thinking': {
                'system': PromptTemplate(
                    name="systemic_thinking_system",
                    system_prompt="""You are designing learning objectives for Systems Thinking competency.

Focus on:
- Understanding system boundaries and interfaces
- Identifying emergent properties and behaviors
- Analyzing system interactions and dependencies
- Considering lifecycle implications
- Balancing stakeholder perspectives and trade-offs

Emphasize holistic view and complex system understanding in {industry} context.""",
                    human_prompt="",
                    variables=[]
                )
            },
            'requirements_management': {
                'system': PromptTemplate(
                    name="requirements_system",
                    system_prompt="""You are designing learning objectives for Requirements Management competency.

Focus on:
- Requirements elicitation and analysis techniques
- Requirements documentation and traceability
- Requirements validation and verification
- Change management and configuration control
- Stakeholder communication and negotiation

Emphasize practical application with {company_name}'s requirements tools and processes.""",
                    human_prompt="",
                    variables=[]
                )
            }
        }

    def _initialize_quality_criteria(self) -> Dict[str, str]:
        """Initialize quality criteria for objectives"""
        return {
            'specific': 'Clearly defined outcome with precise scope and boundaries',
            'measurable': 'Observable behaviors or deliverables that can be assessed',
            'achievable': 'Realistic given participant background and available resources',
            'relevant': 'Directly applicable to role responsibilities and company needs',
            'time_bound': 'Specific timeframe appropriate for learning complexity',
            'company_alignment': 'Uses company-specific processes, methods, and tools',
            'incose_compliance': 'Aligns with INCOSE SE competency framework',
            'business_value': 'Addresses real business challenges and opportunities'
        }

    def _get_industry_expertise(self, industry: str) -> str:
        """Get industry-specific expertise guidance"""
        expertise_map = {
            'Automotive': 'Automotive systems engineering, ISO 26262 functional safety, ASPICE processes, connected and autonomous vehicles, electrification',
            'Aerospace': 'Aerospace systems engineering, DO-178C software certification, AS9100 quality management, aircraft systems integration',
            'Healthcare': 'Medical device development, FDA regulations, IEC 62304, clinical validation, patient safety, regulatory compliance',
            'Finance': 'Financial systems architecture, regulatory compliance (SOX, Basel), risk management, security architecture',
            'Manufacturing': 'Industrial automation, lean manufacturing, Industry 4.0, supply chain integration, quality systems',
            'Telecommunications': '5G/6G networks, telecommunications standards, network architecture, service orchestration',
            'Energy': 'Power systems, smart grid, renewable energy integration, grid modernization, energy storage',
            'Defense': 'Defense acquisition, security architecture, interoperability, mission-critical systems',
            'Software': 'Software architecture, DevOps, cloud-native systems, microservices, API design'
        }
        return expertise_map.get(industry, 'General systems engineering principles and best practices')

    def _get_archetype_guidance(self, archetype: str) -> str:
        """Get archetype-specific guidance"""
        guidance_map = {
            'Common basic understanding': 'Focus on foundational concepts, broad applicability, interactive workshops, basic terminology and principles.',
            'SE for managers': 'Emphasize strategic perspective, decision-making support, business value, leadership responsibilities.',
            'Orientation in pilot project': 'Provide project-specific introduction, role clarity, immediate contribution, guided learning.',
            'Needs-based, project-oriented training': 'Address specific project needs, hands-on application, immediate use, measurable project outcomes.',
            'Continuous support': 'Ongoing development, progressive skill building, mentoring relationship, long-term capability growth.',
            'Train the trainer': 'Master-level competency, teaching capability, material development, assessment skills, internal expertise building.'
        }
        return guidance_map.get(archetype, 'Provide practical, applicable learning appropriate for the participant level.')

    def _get_competency_focus(self, competency: str) -> str:
        """Get competency-specific focus guidance"""
        focus_map = {
            'Systemic thinking': 'Emphasize holistic system view, emergent properties, interfaces, lifecycle perspective, stakeholder balance.',
            'Requirements management': 'Focus on elicitation, analysis, documentation, traceability, validation, change control.',
            'System architecture design': 'Emphasize architectural patterns, design decisions, trade-off analysis, interface definition.',
            'Technical risk management': 'Focus on risk identification, analysis, mitigation strategies, monitoring, contingency planning.',
            'Integration': 'Emphasize integration planning, interface management, testing strategies, system validation.',
            'Validation': 'Focus on validation planning, acceptance criteria, user needs verification, operational readiness.',
            'Verification': 'Emphasize test planning, requirement verification, design validation, compliance demonstration.',
            'Configuration management': 'Focus on change control, version management, baseline management, audit processes.',
            'Process improvement': 'Emphasize process assessment, improvement planning, implementation, measurement, continuous improvement.',
            'Communication': 'Focus on stakeholder communication, documentation, presentation, facilitation, negotiation.',
            'Teamwork': 'Emphasize collaboration, conflict resolution, team dynamics, leadership, cross-functional coordination.',
            'Technical leadership': 'Focus on technical decision-making, guidance, mentoring, innovation, strategic thinking.',
            'Management': 'Emphasize planning, resource management, performance monitoring, stakeholder management.',
            'Quality assurance': 'Focus on quality planning, standards compliance, audit processes, continuous improvement.',
            'System safety': 'Emphasize hazard analysis, safety requirements, risk assessment, safety case development.',
            'Human factors': 'Focus on user experience, ergonomics, cognitive load, human-system interaction, usability.'
        }
        return focus_map.get(competency, 'Apply competency principles effectively in the specific work context.')

    def _format_quality_criteria(self) -> str:
        """Format quality criteria for prompt"""
        criteria_text = []
        for criterion, description in self.quality_criteria.items():
            criteria_text.append(f"- {criterion.replace('_', ' ').title()}: {description}")
        return "\\n".join(criteria_text)

    def _format_company_context(self, context: CompanyPMTContext) -> str:
        """Format company context for prompt"""
        return f"""Company: {context.company_name}
Industry: {context.industry_domain}
Business Domain: {context.business_domain}
SE Maturity: {context.se_maturity_level}
Organization Size: {context.organizational_size}"""

    def _format_pmt_details(self, context: CompanyPMTContext) -> str:
        """Format PMT details for prompt"""
        details = []

        if context.processes:
            details.append(f"Processes: {', '.join(context.processes)}")

        if context.methods:
            details.append(f"Methods: {', '.join(context.methods)}")

        if context.tools:
            details.append(f"Tools: {', '.join(context.tools)}")

        if context.current_challenges:
            details.append(f"Challenges: {', '.join(context.current_challenges)}")

        if context.regulatory_requirements:
            details.append(f"Regulations: {', '.join(context.regulatory_requirements)}")

        return "\\n".join(details) if details else "Standard SE practices and tools"

    def _get_learning_format_guidance(self, archetype: str) -> str:
        """Get learning format guidance for archetype"""
        format_map = {
            'Common basic understanding': 'Learning Format: Interactive workshop (4-8 hours) with group exercises and discussions.',
            'SE for managers': 'Learning Format: Executive briefing (2-4 hours) with strategic focus and decision frameworks.',
            'Orientation in pilot project': 'Learning Format: Guided orientation (1-2 weeks) with project mentoring and shadowing.',
            'Needs-based, project-oriented training': 'Learning Format: On-the-job training (2-4 weeks) with hands-on project work.',
            'Continuous support': 'Learning Format: Ongoing mentoring (3-6 months) with progressive skill development.',
            'Train the trainer': 'Learning Format: Certification program (3-6 months) with teaching assignments and assessments.'
        }
        return format_map.get(archetype, 'Learning Format: Workshop or training session appropriate for competency level.')

    def _get_timeframe_guidance(self, archetype: str, maturity_level: str) -> str:
        """Get timeframe guidance based on archetype and maturity"""
        base_timeframes = {
            'Common basic understanding': '4-8 hours',
            'SE for managers': '2-4 hours',
            'Orientation in pilot project': '1-2 weeks',
            'Needs-based, project-oriented training': '2-4 weeks',
            'Continuous support': '3-6 months',
            'Train the trainer': '3-6 months'
        }

        base_time = base_timeframes.get(archetype, '1-2 weeks')

        # Adjust based on maturity level
        if maturity_level == 'developing':
            adjustment = ' (may need additional foundation time)'
        elif maturity_level == 'expert':
            adjustment = ' (may be accelerated)'
        else:
            adjustment = ''

        return f"Timeframe Guidance: {base_time}{adjustment}"

def main():
    """Test the prompt engineering system"""
    from company_context_extractor import CompanyContextExtractor, CompanyPMTContext

    prompt_engineer = ObjectivePromptEngineer()

    # Test with sample company context
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

    # Test different archetype combinations
    test_cases = [
        ("Systemic thinking", "System engineer", "Common basic understanding"),
        ("Requirements management", "Requirements engineer", "Needs-based, project-oriented training"),
        ("Technical leadership", "Senior engineer", "Train the trainer")
    ]

    for competency, role, archetype in test_cases:
        print(f"\\n=== Testing {competency} + {archetype} ===")

        system_prompt, human_prompt = prompt_engineer.generate_customized_prompt(
            competency=competency,
            role=role,
            archetype=archetype,
            company_context=test_context,
            template_context="Sample template: At the end of the training, participants will understand system boundaries...",
            additional_requirements=["Must include practical exercise", "Focus on automotive safety"]
        )

        print("SYSTEM PROMPT:")
        print(system_prompt[:500] + "..." if len(system_prompt) > 500 else system_prompt)

        print("\\nHUMAN PROMPT:")
        print(human_prompt[:500] + "..." if len(human_prompt) > 500 else human_prompt)

if __name__ == "__main__":
    main()