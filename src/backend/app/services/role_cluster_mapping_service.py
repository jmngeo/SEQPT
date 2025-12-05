"""
AI-powered role cluster mapping service.
Maps organization-specific roles to SE role clusters using OpenAI.

Based on the SE framework by Ulf Koenemann et al.
Reference: "Identification of stakeholder-specific Systems Engineering competencies for industry"
"""

import os
import json
from typing import List, Dict, Any, Optional
from openai import OpenAI
import uuid


class RoleClusterMappingService:
    """Service for mapping organization roles to SE role clusters"""

    def __init__(self, db_session=None):
        """
        Initialize the service

        Args:
            db_session: SQLAlchemy database session (optional, for standalone use)
        """
        self.client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        # Use gpt-4o-mini for cost-effective role mapping (90% cheaper than gpt-4-turbo)
        # Supports JSON mode and provides good reasoning for role classification
        self.model = "gpt-4o-mini"
        self.db_session = db_session

    def get_all_role_clusters_from_db(self):
        """Fetch all 14 SE role clusters from database"""
        if not self.db_session:
            raise ValueError("Database session not provided")

        from app.models import RoleCluster
        clusters = self.db_session.query(RoleCluster).order_by(RoleCluster.id).all()
        return [
            {
                'id': cluster.id,
                'name': cluster.role_cluster_name,
                'description': cluster.role_cluster_description
            }
            for cluster in clusters
        ]

    def get_all_role_clusters_static(self) -> List[Dict[str, Any]]:
        """
        Get all 14 SE role clusters (static version for POC)
        This can be used when database is not available
        """
        return [
            {
                'id': 1,
                'name': 'Customer',
                'description': 'Party that orders or uses the service/product with influence on system design.'
            },
            {
                'id': 2,
                'name': 'Customer Representative',
                'description': 'Interface between customer and company, voice for customer requirements.'
            },
            {
                'id': 3,
                'name': 'Project Manager',
                'description': 'Responsible for project planning, coordination, and achieving goals within constraints.'
            },
            {
                'id': 4,
                'name': 'System Engineer',
                'description': 'Oversees requirements, system decomposition, interfaces, and integration planning.'
            },
            {
                'id': 5,
                'name': 'Specialist Developer',
                'description': 'Develops in specific areas (software, hardware, etc.) based on system specifications.'
            },
            {
                'id': 6,
                'name': 'Production Planner/Coordinator',
                'description': 'Prepares product realization and transfer to customer.'
            },
            {
                'id': 7,
                'name': 'Production Employee',
                'description': 'Handles implementation, assembly, manufacture, and product integration.'
            },
            {
                'id': 8,
                'name': 'Quality Engineer/Manager',
                'description': 'Ensures quality standards are maintained and cooperates with V&V.'
            },
            {
                'id': 9,
                'name': 'Verification and Validation (V&V) Operator',
                'description': 'Performs system verification and validation activities.'
            },
            {
                'id': 10,
                'name': 'Service Technician',
                'description': 'Handles installation, commissioning, training, maintenance, and repair.'
            },
            {
                'id': 11,
                'name': 'Process and Policy Manager',
                'description': 'Develops internal guidelines and monitors process compliance.'
            },
            {
                'id': 12,
                'name': 'Internal Support',
                'description': 'Provides advisory and support during development (IT, qualification, SE support).'
            },
            {
                'id': 13,
                'name': 'Innovation Management',
                'description': 'Focuses on commercial implementation of products/services and new business models.'
            },
            {
                'id': 14,
                'name': 'Management',
                'description': 'Decision-makers providing company vision, goals, and project oversight.'
            }
        ]

    def build_mapping_prompt(self,
                            org_role_title: str,
                            org_role_description: str,
                            org_role_responsibilities: Optional[List[str]] = None,
                            org_role_skills: Optional[List[str]] = None,
                            role_clusters: Optional[List[Dict[str, Any]]] = None) -> str:
        """Build the prompt for OpenAI to map a role to clusters"""

        if role_clusters is None:
            # Use static clusters for POC
            role_clusters = self.get_all_role_clusters_static()

        # Format role clusters for the prompt
        clusters_text = "\n".join([
            f"{i+1}. **{cluster['name']}**: {cluster['description']}"
            for i, cluster in enumerate(role_clusters)
        ])

        # Build role information section
        role_info = f"**Role Title**: {org_role_title}\n\n**Role Description**: {org_role_description}"

        if org_role_responsibilities:
            role_info += f"\n\n**Key Responsibilities**:\n" + "\n".join([f"- {r}" for r in org_role_responsibilities])

        if org_role_skills:
            role_info += f"\n\n**Required Skills**:\n" + "\n".join([f"- {s}" for s in org_role_skills])

        prompt = f"""You are an expert in Systems Engineering role classification based on the SE framework developed by Ulf Koenemann et al. at Fraunhofer IEM.

Your task is to analyze the provided organization role and determine if it matches one or more SE Role Clusters.

## Organization Role to Analyze:

{role_info}

## Available SE Role Clusters:

{clusters_text}

## Instructions:

1. Analyze the role's responsibilities, skills, and description carefully
2. **CRITICAL: Check if this is a Systems Engineering role first**
   - SE roles involve: requirements, design, integration, testing, V&V, technical coordination, production, quality, service
   - SE roles can include: project management, process management, innovation management, technical support
   - SE roles are primarily technical/engineering-focused with product/system development context
3. **EXCLUDE these PURE business roles completely** (return empty mappings array):
   - **Pure Payroll/Benefits**: Employee compensation, benefits administration, payroll processing (NOT competency/qualification management)
   - **Pure Finance/Accounting**: Bookkeeping, financial reporting, tax preparation, accounts payable/receivable, treasury operations
   - **Pure Marketing**: Advertising campaigns, brand management, social media marketing, market research (NOT product/service innovation)
   - **Pure Sales**: Sales quotas, commission management, CRM systems, sales territories, deal closing (NOT technical sales or customer requirements)
   - **Pure Legal**: Contract law, litigation, legal counsel, regulatory filings (NOT engineering standards/compliance)
   - **Pure Administration**: Office management, facilities management, receptionist, general administrative support
4. **INCLUDE these SE-related roles** (can map to clusters):
   - **Innovation Management**: Commercial implementation of products/services, new business models, technology commercialization (Cluster #13)
   - **HR for SE**: Competency development, qualification management, SE training programs, technical recruiting (relates to Process #6)
   - **Internal Support**: IT support for SE tools, SE qualification support, SE process support (Cluster #12)
   - **Business Analysis**: Systems/mission analysis, stakeholder requirements (if technical - Process #17)
   - **Project Management**: Technical project coordination (Cluster #3)
5. Identify which SE role cluster(s) best match this role **ONLY if there is a strong alignment**
6. A role may map to multiple clusters if responsibilities span multiple areas
7. Provide a confidence score (0-100%) for each mapping based on how well the responsibilities align
8. **ONLY include mappings with confidence >= 80%** - We prefer high-quality matches
9. **If the role is pure business (non-SE) or no cluster has >= 80% confidence, return an empty mappings array**
10. Do NOT force a match - it's better to have no mapping than a poor one
11. Explain your reasoning for each mapping in detail
12. Identify which specific responsibilities align with each cluster
13. Mark the strongest match as the primary mapping (if any mappings exist)

## Response Format (JSON):

Return your analysis in the following JSON format:

{{
  "mappings": [
    {{
      "cluster_name": "Name of the SE cluster (exact match from list above)",
      "confidence_score": 85,
      "reasoning": "Detailed explanation of why this cluster matches, referencing specific responsibilities and how they align with the cluster's description",
      "matched_responsibilities": ["Specific responsibility 1 from the role", "Specific responsibility 2"],
      "is_primary": true
    }},
    {{
      "cluster_name": "Another cluster name",
      "confidence_score": 82,
      "reasoning": "Explanation for secondary match",
      "matched_responsibilities": ["Responsibility that matches this cluster"],
      "is_primary": false
    }}
  ],
  "overall_analysis": "Brief summary of the role's primary focus and how it fits (or doesn't fit) into the SE framework. If no good match exists, explain why and mention that this should be a custom role."
}}

IMPORTANT:
- Return ONLY valid JSON, no additional text or markdown formatting
- Use exact cluster names from the list provided above
- **ONLY include mappings with confidence >= 80%**
- If no clusters match well, return "mappings": [] (empty array)
- Do NOT force low-confidence matches
- If mappings exist, mark exactly ONE as "is_primary": true (the best match)
- Order mappings by confidence_score (highest first)
- Be specific and detailed in your reasoning
- Consider the Systems Engineering context when analyzing the role
"""

        return prompt

    def map_single_role(self,
                       org_role_title: str,
                       org_role_description: str,
                       org_role_responsibilities: Optional[List[str]] = None,
                       org_role_skills: Optional[List[str]] = None,
                       role_clusters: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        """
        Use AI to map a single organization role to SE-QPT clusters

        Args:
            org_role_title: The title of the organization's role
            org_role_description: Description of what this role does
            org_role_responsibilities: List of key responsibilities
            org_role_skills: List of required skills
            role_clusters: Optional list of role clusters (uses static if not provided)

        Returns:
            {
                'mappings': [
                    {
                        'cluster_name': '...',
                        'cluster_id': X,
                        'confidence_score': 85,
                        'reasoning': '...',
                        'matched_responsibilities': [...],
                        'is_primary': true
                    }
                ],
                'overall_analysis': '...'
            }
        """

        if role_clusters is None:
            role_clusters = self.get_all_role_clusters_static()

        prompt = self.build_mapping_prompt(
            org_role_title,
            org_role_description,
            org_role_responsibilities,
            org_role_skills,
            role_clusters
        )

        try:
            print(f"[INFO] Mapping role: {org_role_title}")

            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert in Systems Engineering role classification based on the SE framework. Always return valid JSON."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.3,  # Lower temperature for more deterministic results
                response_format={"type": "json_object"}
            )

            result = json.loads(response.choices[0].message.content)

            # Validate and enrich with cluster IDs
            role_clusters_map = {rc['name']: rc['id'] for rc in role_clusters}

            for mapping in result.get('mappings', []):
                cluster_name = mapping['cluster_name']
                # Try to find exact match
                cluster_id = role_clusters_map.get(cluster_name)

                if not cluster_id:
                    # Try fuzzy matching (case-insensitive, partial match)
                    for name, cid in role_clusters_map.items():
                        if cluster_name.lower() in name.lower() or name.lower() in cluster_name.lower():
                            cluster_id = cid
                            mapping['cluster_name'] = name  # Update to exact name
                            break

                mapping['cluster_id'] = cluster_id

                if not cluster_id:
                    print(f"[WARNING] Could not find cluster ID for: {cluster_name}")

            print(f"[SUCCESS] Mapped {org_role_title} to {len(result.get('mappings', []))} clusters")

            return result

        except Exception as e:
            print(f"[ERROR] AI mapping failed for {org_role_title}: {str(e)}")
            return {
                'mappings': [],
                'overall_analysis': f'Error during AI analysis: {str(e)}',
                'error': str(e)
            }

    def map_multiple_roles(self,
                          roles: List[Dict[str, Any]],
                          role_clusters: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        """
        Map multiple roles at once

        Args:
            roles: List of role dictionaries with keys:
                   - title (required)
                   - description (required)
                   - responsibilities (optional list)
                   - skills (optional list)
            role_clusters: Optional list of role clusters

        Returns:
            {
                'batch_id': '...',
                'total_roles': 5,
                'total_mappings': 12,
                'results': [
                    {
                        'role_title': '...',
                        'mappings': [...],
                        'overall_analysis': '...'
                    }
                ]
            }
        """

        if role_clusters is None:
            role_clusters = self.get_all_role_clusters_static()

        batch_id = str(uuid.uuid4())
        results = []
        total_mappings = 0

        print(f"[INFO] Starting batch mapping for {len(roles)} roles (batch_id: {batch_id})")

        for i, role_data in enumerate(roles, 1):
            role_title = role_data.get('title')
            role_description = role_data.get('description', '')
            role_responsibilities = role_data.get('responsibilities', [])
            role_skills = role_data.get('skills', [])

            print(f"[INFO] Processing role {i}/{len(roles)}: {role_title}")

            # Get AI mapping
            mapping_result = self.map_single_role(
                role_title,
                role_description,
                role_responsibilities,
                role_skills,
                role_clusters
            )

            mappings = mapping_result.get('mappings', [])
            total_mappings += len(mappings)

            results.append({
                'role_title': role_title,
                'role_description': role_description,
                'mappings': mappings,
                'overall_analysis': mapping_result.get('overall_analysis', ''),
                'error': mapping_result.get('error')
            })

        print(f"[SUCCESS] Batch mapping complete. Total mappings: {total_mappings}")

        return {
            'batch_id': batch_id,
            'total_roles': len(roles),
            'total_mappings': total_mappings,
            'results': results
        }

    def calculate_coverage(self,
                          mappings: List[Dict[str, Any]],
                          role_clusters: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        """
        Analyze which role clusters are present in the organization's mapped roles

        NOTE: Organizations are NOT expected to have all 14 role clusters.
        This analysis is purely informational to show which SE role clusters
        are represented in the organization's structure.

        Args:
            mappings: List of confirmed mappings with 'cluster_id' field
            role_clusters: Optional list of role clusters

        Returns:
            {
                'total_available_clusters': 14,
                'mapped_count': 6,
                'mapped_clusters': [...],
                'mapped_cluster_names': ['System Engineer', 'Specialist Developer', ...]
            }
        """

        if role_clusters is None:
            role_clusters = self.get_all_role_clusters_static()

        # Get unique cluster IDs that are mapped
        mapped_cluster_ids = set()
        for mapping in mappings:
            if isinstance(mapping, dict) and 'cluster_id' in mapping:
                mapped_cluster_ids.add(mapping['cluster_id'])

        mapped_clusters = [c for c in role_clusters if c['id'] in mapped_cluster_ids]
        mapped_cluster_names = [c['name'] for c in mapped_clusters]

        return {
            'total_available_clusters': len(role_clusters),
            'mapped_count': len(mapped_clusters),
            'mapped_clusters': mapped_clusters,
            'mapped_cluster_names': mapped_cluster_names
        }
