# AI-Powered Role Cluster Mapping - Implementation Plan

## Executive Summary
This document outlines the implementation plan for an AI-powered role mapping feature that automatically maps organization-specific job roles to the 14 SE-QPT role clusters based on Ulf's research framework.

**Feature Location**: Phase 1 Task 2 - Role Identification/Selection

**Estimated Development Time**: 2-3 weeks

**Dependencies**:
- OpenAI API (already integrated)
- PostgreSQL database (existing)
- Vue 3 frontend (existing)
- Flask backend (existing)

---

## Important Design Principle

**Organizations are NOT expected to have all 14 role clusters.**

The 14 SE-QPT role clusters are a **reference framework**, not a checklist:
- A small startup might have only 3-4 clusters (e.g., System Engineer, Specialist Developer, Management)
- A large corporation might have 10-12 clusters
- Each organization's structure depends on their size, industry, and business model

**What this feature does:**
- Maps organization's **existing** roles to SE-QPT clusters
- Shows which clusters are **present** in the organization
- Helps understand organizational structure in SE terms

**What this feature does NOT do:**
- ❌ Warn about "missing" clusters
- ❌ Recommend hiring for uncovered clusters
- ❌ Suggest organizational changes
- ❌ Imply the organization is incomplete

This is **descriptive** (what you have), not **prescriptive** (what you should have).

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Vue 3)                         │
├─────────────────────────────────────────────────────────────┤
│  1. RoleUploadMapper.vue                                    │
│     - Upload role descriptions (text/JSON/file)             │
│     - Initiate AI mapping process                           │
│                                                              │
│  2. RoleMappingReview.vue                                   │
│     - Display AI suggestions with confidence scores         │
│     - Allow user to accept/reject/modify mappings           │
│     - Show reasoning for each mapping                       │
│                                                              │
│  3. OrganizationStructureAnalysis.vue                       │
│     - Display which role clusters are present               │
│     - Show organizational structure in SE terms             │
│     - Purely informational (no gap warnings)                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (Flask)                          │
├─────────────────────────────────────────────────────────────┤
│  API Endpoints:                                             │
│  - POST /api/phase1/map-roles                               │
│  - GET  /api/phase1/role-mappings/<org_id>                  │
│  - PUT  /api/phase1/role-mappings/<mapping_id>              │
│  - GET  /api/phase1/role-clusters                           │
│  - GET  /api/phase1/organization-structure/<org_id>         │
│                                                              │
│  Services:                                                  │
│  - role_cluster_mapping_service.py                          │
│    • map_organization_roles()                               │
│    • get_role_cluster_descriptions()                        │
│    • calculate_coverage()                                   │
│    • analyze_organization_structure()                       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    AI PROCESSING (OpenAI)                   │
├─────────────────────────────────────────────────────────────┤
│  - GPT-4 model for semantic understanding                   │
│  - Structured prompts with role cluster definitions         │
│  - JSON response format for consistency                     │
│  - Confidence scoring (0-100%)                              │
│  - Multi-cluster mapping support                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE (PostgreSQL)                    │
├─────────────────────────────────────────────────────────────┤
│  New Table: organization_role_mappings                      │
│  - Stores org roles and their cluster mappings              │
│  - Tracks confidence scores and reasoning                   │
│  - Records user confirmations                               │
│                                                              │
│  Existing Tables:                                           │
│  - role_cluster (14 SE-QPT standard roles)                  │
│  - organizations                                            │
│  - organization_roles                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### New Table: `organization_role_mappings`

```sql
CREATE TABLE organization_role_mappings (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,

    -- Organization's custom role information
    org_role_title VARCHAR(255) NOT NULL,
    org_role_description TEXT,
    org_role_responsibilities TEXT, -- JSON array of responsibilities
    org_role_skills TEXT, -- JSON array of required skills

    -- Mapping to SE-QPT role cluster
    mapped_cluster_id INTEGER NOT NULL REFERENCES role_cluster(id),

    -- AI analysis metadata
    confidence_score DECIMAL(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
    mapping_reasoning TEXT, -- Why this cluster was selected
    matched_responsibilities TEXT, -- JSON array of which responsibilities matched

    -- User validation
    user_confirmed BOOLEAN DEFAULT FALSE,
    confirmed_by INTEGER REFERENCES new_survey_user(id),
    confirmed_at TIMESTAMP,

    -- Source tracking
    upload_source VARCHAR(50), -- 'manual', 'file_upload', 'api'
    upload_batch_id UUID, -- Group related uploads

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Ensure no duplicate mappings for same role to same cluster
    UNIQUE(organization_id, org_role_title, mapped_cluster_id)
);

-- Index for fast queries
CREATE INDEX idx_org_role_mappings_org_id ON organization_role_mappings(organization_id);
CREATE INDEX idx_org_role_mappings_cluster_id ON organization_role_mappings(mapped_cluster_id);
CREATE INDEX idx_org_role_mappings_batch_id ON organization_role_mappings(upload_batch_id);
CREATE INDEX idx_org_role_mappings_confirmed ON organization_role_mappings(user_confirmed);

-- Audit trigger
CREATE TRIGGER update_org_role_mappings_timestamp
    BEFORE UPDATE ON organization_role_mappings
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();
```

---

## Backend Implementation

### File 1: `src/backend/app/services/role_cluster_mapping_service.py`

```python
"""
AI-powered role cluster mapping service.
Maps organization-specific roles to SE-QPT role clusters using OpenAI.
"""

import os
import json
from typing import List, Dict, Any, Optional
from openai import OpenAI
from app.models import db, RoleCluster, OrganizationRoleMapping
import uuid


class RoleClusterMappingService:
    """Service for mapping organization roles to SE-QPT role clusters"""

    def __init__(self):
        self.client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        self.model = "gpt-4"

    def get_all_role_clusters(self) -> List[Dict[str, Any]]:
        """Fetch all 14 SE-QPT role clusters from database"""
        clusters = RoleCluster.query.order_by(RoleCluster.id).all()
        return [
            {
                'id': cluster.id,
                'name': cluster.role_cluster_name,
                'description': cluster.role_cluster_description
            }
            for cluster in clusters
        ]

    def build_mapping_prompt(self,
                            org_role_title: str,
                            org_role_description: str,
                            org_role_responsibilities: Optional[List[str]] = None,
                            org_role_skills: Optional[List[str]] = None) -> str:
        """Build the prompt for OpenAI to map a role to clusters"""

        role_clusters = self.get_all_role_clusters()

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

        prompt = f"""You are an expert in Systems Engineering role classification based on the SE-QPT framework developed by Ulf Könemann et al.

Your task is to analyze the provided organization role and map it to one or more SE-QPT Role Clusters.

## Organization Role to Analyze:

{role_info}

## Available SE-QPT Role Clusters:

{clusters_text}

## Instructions:

1. Analyze the role's responsibilities, skills, and description
2. Identify which SE-QPT role cluster(s) best match this role
3. A role may map to multiple clusters if responsibilities span multiple areas
4. Provide a confidence score (0-100%) for each mapping
5. Only include mappings with confidence >= 30%
6. Explain your reasoning for each mapping
7. Identify which specific responsibilities align with each cluster

## Response Format (JSON):

Return your analysis in the following JSON format:

{{
  "mappings": [
    {{
      "cluster_name": "Name of the SE-QPT cluster",
      "confidence_score": 85,
      "reasoning": "Explanation of why this cluster matches",
      "matched_responsibilities": ["Specific responsibility 1", "Specific responsibility 2"],
      "is_primary": true
    }}
  ],
  "overall_analysis": "Brief summary of the role's primary focus and how it fits into the SE framework"
}}

IMPORTANT:
- Return ONLY valid JSON, no additional text
- Mark the best match as "is_primary": true
- Order mappings by confidence_score (highest first)
- Be specific in your reasoning
"""

        return prompt

    def map_single_role(self,
                       org_role_title: str,
                       org_role_description: str,
                       org_role_responsibilities: Optional[List[str]] = None,
                       org_role_skills: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Use AI to map a single organization role to SE-QPT clusters

        Returns:
            {
                'mappings': [...],
                'overall_analysis': '...'
            }
        """

        prompt = self.build_mapping_prompt(
            org_role_title,
            org_role_description,
            org_role_responsibilities,
            org_role_skills
        )

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert in Systems Engineering role classification. Always return valid JSON."
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
            role_clusters = {rc['name']: rc['id'] for rc in self.get_all_role_clusters()}

            for mapping in result.get('mappings', []):
                cluster_name = mapping['cluster_name']
                # Try to find exact match or close match
                cluster_id = role_clusters.get(cluster_name)
                if not cluster_id:
                    # Try fuzzy matching
                    for name, cid in role_clusters.items():
                        if cluster_name.lower() in name.lower() or name.lower() in cluster_name.lower():
                            cluster_id = cid
                            break

                mapping['cluster_id'] = cluster_id

            return result

        except Exception as e:
            print(f"[ERROR] AI mapping failed: {str(e)}")
            return {
                'mappings': [],
                'overall_analysis': f'Error during AI analysis: {str(e)}',
                'error': str(e)
            }

    def map_multiple_roles(self,
                          organization_id: int,
                          roles: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Map multiple roles at once and save to database

        Args:
            organization_id: The organization ID
            roles: List of role dictionaries with keys:
                   - title (required)
                   - description (required)
                   - responsibilities (optional list)
                   - skills (optional list)

        Returns:
            {
                'batch_id': '...',
                'total_roles': 5,
                'total_mappings': 12,
                'results': [...]
            }
        """

        batch_id = str(uuid.uuid4())
        results = []
        total_mappings = 0

        for role_data in roles:
            role_title = role_data.get('title')
            role_description = role_data.get('description', '')
            role_responsibilities = role_data.get('responsibilities', [])
            role_skills = role_data.get('skills', [])

            # Get AI mapping
            mapping_result = self.map_single_role(
                role_title,
                role_description,
                role_responsibilities,
                role_skills
            )

            # Save to database
            saved_mappings = []
            for mapping in mapping_result.get('mappings', []):
                if mapping.get('cluster_id'):
                    try:
                        db_mapping = OrganizationRoleMapping(
                            organization_id=organization_id,
                            org_role_title=role_title,
                            org_role_description=role_description,
                            org_role_responsibilities=json.dumps(role_responsibilities) if role_responsibilities else None,
                            org_role_skills=json.dumps(role_skills) if role_skills else None,
                            mapped_cluster_id=mapping['cluster_id'],
                            confidence_score=mapping['confidence_score'],
                            mapping_reasoning=mapping['reasoning'],
                            matched_responsibilities=json.dumps(mapping.get('matched_responsibilities', [])),
                            user_confirmed=False,
                            upload_source='ai_batch',
                            upload_batch_id=batch_id
                        )

                        db.session.add(db_mapping)
                        saved_mappings.append(mapping)
                        total_mappings += 1

                    except Exception as e:
                        print(f"[ERROR] Failed to save mapping: {str(e)}")

            results.append({
                'role_title': role_title,
                'mappings': saved_mappings,
                'overall_analysis': mapping_result.get('overall_analysis', '')
            })

        # Commit all mappings
        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return {
                'error': f'Failed to save mappings: {str(e)}',
                'batch_id': batch_id,
                'total_roles': len(roles),
                'total_mappings': 0,
                'results': []
            }

        return {
            'batch_id': batch_id,
            'total_roles': len(roles),
            'total_mappings': total_mappings,
            'results': results
        }

    def get_coverage_analysis(self, organization_id: int) -> Dict[str, Any]:
        """
        Analyze which role clusters are covered by the organization's roles

        Returns:
            {
                'total_clusters': 14,
                'covered_clusters': [...],
                'missing_clusters': [...],
                'coverage_percentage': 71.4,
                'recommendations': [...]
            }
        """

        all_clusters = self.get_all_role_clusters()

        # Get confirmed mappings for this organization
        mappings = OrganizationRoleMapping.query.filter_by(
            organization_id=organization_id,
            user_confirmed=True
        ).all()

        # Get unique cluster IDs that are covered
        covered_cluster_ids = set(m.mapped_cluster_id for m in mappings)

        covered_clusters = [c for c in all_clusters if c['id'] in covered_cluster_ids]
        missing_clusters = [c for c in all_clusters if c['id'] not in covered_cluster_ids]

        coverage_percentage = (len(covered_clusters) / len(all_clusters)) * 100

        # Generate recommendations
        recommendations = []

        # Prioritize critical missing clusters
        critical_clusters = ['System Engineer', 'Verification and Validation (V&V) Operator', 'Quality Engineer/Manager']
        missing_critical = [c for c in missing_clusters if c['name'] in critical_clusters]

        if missing_critical:
            recommendations.append({
                'priority': 'high',
                'message': f"Consider adding roles for: {', '.join([c['name'] for c in missing_critical])}",
                'clusters': missing_critical
            })

        if coverage_percentage < 50:
            recommendations.append({
                'priority': 'high',
                'message': f"Coverage is low ({coverage_percentage:.1f}%). Consider reviewing your organizational structure.",
                'clusters': []
            })

        return {
            'total_clusters': len(all_clusters),
            'covered_count': len(covered_clusters),
            'missing_count': len(missing_clusters),
            'covered_clusters': covered_clusters,
            'missing_clusters': missing_clusters,
            'coverage_percentage': round(coverage_percentage, 1),
            'recommendations': recommendations
        }
```

---

## API Endpoints

### File 2: `src/backend/app/routes.py` (additions)

```python
# Import the new service
from app.services.role_cluster_mapping_service import RoleClusterMappingService

# Initialize service
role_mapping_service = RoleClusterMappingService()


@app.route('/api/phase1/role-clusters', methods=['GET'])
def get_role_clusters():
    """Get all 14 SE-QPT role clusters"""
    try:
        clusters = role_mapping_service.get_all_role_clusters()
        return jsonify({
            'success': True,
            'role_clusters': clusters,
            'total': len(clusters)
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/phase1/map-roles', methods=['POST'])
def map_organization_roles():
    """
    Map organization roles to SE-QPT clusters using AI

    Request body:
    {
        "organization_id": 123,
        "roles": [
            {
                "title": "Senior Software Developer",
                "description": "Develops embedded software...",
                "responsibilities": ["Design software modules", ...],
                "skills": ["C++", "Python", ...]
            }
        ]
    }
    """
    try:
        data = request.get_json()
        organization_id = data.get('organization_id')
        roles = data.get('roles', [])

        if not organization_id:
            return jsonify({'success': False, 'error': 'organization_id is required'}), 400

        if not roles:
            return jsonify({'success': False, 'error': 'roles array is required'}), 400

        # Perform AI mapping
        result = role_mapping_service.map_multiple_roles(organization_id, roles)

        if 'error' in result:
            return jsonify({'success': False, 'error': result['error']}), 500

        return jsonify({
            'success': True,
            'data': result
        })

    except Exception as e:
        app.logger.error(f"[ERROR] Role mapping failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/phase1/role-mappings/<int:org_id>', methods=['GET'])
def get_role_mappings(org_id):
    """Get all role mappings for an organization"""
    try:
        mappings = OrganizationRoleMapping.query.filter_by(
            organization_id=org_id
        ).order_by(OrganizationRoleMapping.org_role_title).all()

        result = []
        for m in mappings:
            result.append({
                'id': m.id,
                'org_role_title': m.org_role_title,
                'org_role_description': m.org_role_description,
                'mapped_cluster': {
                    'id': m.mapped_cluster_id,
                    'name': m.role_cluster.role_cluster_name if m.role_cluster else None,
                    'description': m.role_cluster.role_cluster_description if m.role_cluster else None
                },
                'confidence_score': float(m.confidence_score) if m.confidence_score else None,
                'reasoning': m.mapping_reasoning,
                'matched_responsibilities': json.loads(m.matched_responsibilities) if m.matched_responsibilities else [],
                'user_confirmed': m.user_confirmed,
                'created_at': m.created_at.isoformat() if m.created_at else None
            })

        return jsonify({
            'success': True,
            'mappings': result,
            'total': len(result)
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/phase1/role-mappings/<int:mapping_id>', methods=['PUT'])
def update_role_mapping(mapping_id):
    """
    Update a role mapping (confirm, reject, or modify)

    Request body:
    {
        "user_confirmed": true,
        "confirmed_by": 456
    }
    """
    try:
        data = request.get_json()
        mapping = OrganizationRoleMapping.query.get(mapping_id)

        if not mapping:
            return jsonify({'success': False, 'error': 'Mapping not found'}), 404

        if 'user_confirmed' in data:
            mapping.user_confirmed = data['user_confirmed']
            mapping.confirmed_by = data.get('confirmed_by')
            if data['user_confirmed']:
                from datetime import datetime
                mapping.confirmed_at = datetime.utcnow()

        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Mapping updated successfully'
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/phase1/role-mappings/<int:mapping_id>', methods=['DELETE'])
def delete_role_mapping(mapping_id):
    """Delete a role mapping"""
    try:
        mapping = OrganizationRoleMapping.query.get(mapping_id)

        if not mapping:
            return jsonify({'success': False, 'error': 'Mapping not found'}), 404

        db.session.delete(mapping)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Mapping deleted successfully'
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/phase1/coverage-analysis/<int:org_id>', methods=['GET'])
def get_coverage_analysis(org_id):
    """Get role cluster coverage analysis for an organization"""
    try:
        analysis = role_mapping_service.get_coverage_analysis(org_id)

        return jsonify({
            'success': True,
            'analysis': analysis
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
```

---

## Frontend Implementation

### File 3: `src/frontend/src/components/phase1/task2/RoleUploadMapper.vue`

```vue
<template>
  <v-card>
    <v-card-title>
      <v-icon left>mdi-robot</v-icon>
      AI-Powered Role Mapping
    </v-card-title>

    <v-card-text>
      <v-alert type="info" variant="tonal" class="mb-4">
        Upload your organization's role descriptions and let AI automatically map them to SE-QPT role clusters.
      </v-alert>

      <v-tabs v-model="tab">
        <v-tab value="manual">Manual Entry</v-tab>
        <v-tab value="json">JSON Upload</v-tab>
      </v-tabs>

      <v-window v-model="tab" class="mt-4">
        <!-- Manual Entry Tab -->
        <v-window-item value="manual">
          <v-form ref="roleForm">
            <v-text-field
              v-model="currentRole.title"
              label="Role Title"
              hint="e.g., Senior Embedded Software Developer"
              required
            ></v-text-field>

            <v-textarea
              v-model="currentRole.description"
              label="Role Description"
              rows="3"
              hint="Brief description of this role"
              required
            ></v-textarea>

            <v-combobox
              v-model="currentRole.responsibilities"
              label="Key Responsibilities"
              multiple
              chips
              hint="Press Enter after each responsibility"
            ></v-combobox>

            <v-combobox
              v-model="currentRole.skills"
              label="Required Skills"
              multiple
              chips
              hint="Press Enter after each skill"
            ></v-combobox>

            <v-btn color="primary" @click="addRole" class="mt-2">
              <v-icon left>mdi-plus</v-icon>
              Add Role
            </v-btn>
          </v-form>

          <!-- Added Roles List -->
          <v-list v-if="roles.length > 0" class="mt-4">
            <v-list-subheader>Roles to Map ({{ roles.length }})</v-list-subheader>
            <v-list-item v-for="(role, index) in roles" :key="index">
              <template v-slot:prepend>
                <v-icon>mdi-account-circle</v-icon>
              </template>

              <v-list-item-title>{{ role.title }}</v-list-item-title>
              <v-list-item-subtitle>{{ role.description }}</v-list-item-subtitle>

              <template v-slot:append>
                <v-btn icon size="small" @click="removeRole(index)">
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-list-item>
          </v-list>
        </v-window-item>

        <!-- JSON Upload Tab -->
        <v-window-item value="json">
          <v-file-input
            label="Upload JSON file"
            accept=".json"
            @change="handleFileUpload"
            prepend-icon="mdi-file-upload"
          ></v-file-input>

          <v-alert type="info" variant="tonal">
            <strong>Expected JSON format:</strong>
            <pre class="mt-2">{{ jsonExample }}</pre>
          </v-alert>
        </v-window-item>
      </v-window>
    </v-card-text>

    <v-card-actions>
      <v-spacer></v-spacer>
      <v-btn @click="$emit('cancel')">Cancel</v-btn>
      <v-btn
        color="primary"
        @click="startMapping"
        :disabled="roles.length === 0 || loading"
        :loading="loading"
      >
        <v-icon left>mdi-robot</v-icon>
        Start AI Mapping
      </v-btn>
    </v-card-actions>
  </v-card>
</template>

<script>
export default {
  name: 'RoleUploadMapper',

  props: {
    organizationId: {
      type: Number,
      required: true
    }
  },

  data() {
    return {
      tab: 'manual',
      loading: false,
      currentRole: {
        title: '',
        description: '',
        responsibilities: [],
        skills: []
      },
      roles: [],
      jsonExample: `[
  {
    "title": "Senior Software Developer",
    "description": "Develops embedded software...",
    "responsibilities": [
      "Design software modules",
      "Write unit tests"
    ],
    "skills": ["C++", "Python"]
  }
]`
    }
  },

  methods: {
    addRole() {
      if (!this.currentRole.title || !this.currentRole.description) {
        alert('Please provide at least a title and description')
        return
      }

      this.roles.push({ ...this.currentRole })

      // Reset form
      this.currentRole = {
        title: '',
        description: '',
        responsibilities: [],
        skills: []
      }
    },

    removeRole(index) {
      this.roles.splice(index, 1)
    },

    handleFileUpload(event) {
      const file = event.target.files[0]
      if (!file) return

      const reader = new FileReader()
      reader.onload = (e) => {
        try {
          const data = JSON.parse(e.target.result)
          if (Array.isArray(data)) {
            this.roles = data
          } else {
            alert('Invalid JSON format. Expected an array of roles.')
          }
        } catch (error) {
          alert('Failed to parse JSON file: ' + error.message)
        }
      }
      reader.readAsText(file)
    },

    async startMapping() {
      this.loading = true

      try {
        const response = await this.$axios.post('/api/phase1/map-roles', {
          organization_id: this.organizationId,
          roles: this.roles
        })

        if (response.data.success) {
          this.$emit('mapping-complete', response.data.data)
        } else {
          alert('Mapping failed: ' + response.data.error)
        }
      } catch (error) {
        alert('Error during mapping: ' + error.message)
      } finally {
        this.loading = false
      }
    }
  }
}
</script>
```

---

## Migration File

### File 4: `src/backend/setup/migrations/011_create_org_role_mappings.sql`

```sql
-- Migration 011: Create organization role mappings table
-- This table stores AI-powered mappings of organization roles to SE-QPT role clusters

CREATE TABLE IF NOT EXISTS organization_role_mappings (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,

    -- Organization's custom role information
    org_role_title VARCHAR(255) NOT NULL,
    org_role_description TEXT,
    org_role_responsibilities TEXT, -- JSON array
    org_role_skills TEXT, -- JSON array

    -- Mapping to SE-QPT role cluster
    mapped_cluster_id INTEGER NOT NULL REFERENCES role_cluster(id),

    -- AI analysis metadata
    confidence_score DECIMAL(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
    mapping_reasoning TEXT,
    matched_responsibilities TEXT, -- JSON array

    -- User validation
    user_confirmed BOOLEAN DEFAULT FALSE,
    confirmed_by INTEGER REFERENCES new_survey_user(id),
    confirmed_at TIMESTAMP,

    -- Source tracking
    upload_source VARCHAR(50),
    upload_batch_id UUID,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Ensure no duplicate mappings
    UNIQUE(organization_id, org_role_title, mapped_cluster_id)
);

-- Indexes
CREATE INDEX idx_org_role_mappings_org_id ON organization_role_mappings(organization_id);
CREATE INDEX idx_org_role_mappings_cluster_id ON organization_role_mappings(mapped_cluster_id);
CREATE INDEX idx_org_role_mappings_batch_id ON organization_role_mappings(upload_batch_id);
CREATE INDEX idx_org_role_mappings_confirmed ON organization_role_mappings(user_confirmed);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_org_role_mappings_timestamp
    BEFORE UPDATE ON organization_role_mappings
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON organization_role_mappings TO seqpt_admin;
GRANT USAGE, SELECT ON SEQUENCE organization_role_mappings_id_seq TO seqpt_admin;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '[SUCCESS] Migration 011: organization_role_mappings table created';
END $$;
```

---

## Model Definition

### File 5: `src/backend/models.py` (additions)

```python
class OrganizationRoleMapping(db.Model):
    """
    Stores AI-powered mappings of organization-specific roles to SE-QPT role clusters
    """
    __tablename__ = 'organization_role_mappings'

    id = db.Column(db.Integer, primary_key=True)
    organization_id = db.Column(db.Integer, db.ForeignKey('organizations.id'), nullable=False)

    # Organization's custom role information
    org_role_title = db.Column(db.String(255), nullable=False)
    org_role_description = db.Column(db.Text)
    org_role_responsibilities = db.Column(db.Text)  # JSON array
    org_role_skills = db.Column(db.Text)  # JSON array

    # Mapping to SE-QPT role cluster
    mapped_cluster_id = db.Column(db.Integer, db.ForeignKey('role_cluster.id'), nullable=False)

    # AI analysis metadata
    confidence_score = db.Column(db.Numeric(5, 2))
    mapping_reasoning = db.Column(db.Text)
    matched_responsibilities = db.Column(db.Text)  # JSON array

    # User validation
    user_confirmed = db.Column(db.Boolean, default=False)
    confirmed_by = db.Column(db.Integer, db.ForeignKey('new_survey_user.id'))
    confirmed_at = db.Column(db.DateTime)

    # Source tracking
    upload_source = db.Column(db.String(50))
    upload_batch_id = db.Column(db.String(36))  # UUID

    # Metadata
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    updated_at = db.Column(db.DateTime, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())

    # Relationships
    organization = db.relationship('Organization', backref='role_mappings')
    role_cluster = db.relationship('RoleCluster', backref='org_mappings')
    confirmed_by_user = db.relationship('NewSurveyUser', foreign_keys=[confirmed_by])

    def to_dict(self):
        import json
        return {
            'id': self.id,
            'organization_id': self.organization_id,
            'org_role_title': self.org_role_title,
            'org_role_description': self.org_role_description,
            'org_role_responsibilities': json.loads(self.org_role_responsibilities) if self.org_role_responsibilities else [],
            'org_role_skills': json.loads(self.org_role_skills) if self.org_role_skills else [],
            'mapped_cluster_id': self.mapped_cluster_id,
            'confidence_score': float(self.confidence_score) if self.confidence_score else None,
            'mapping_reasoning': self.mapping_reasoning,
            'matched_responsibilities': json.loads(self.matched_responsibilities) if self.matched_responsibilities else [],
            'user_confirmed': self.user_confirmed,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class RoleCluster(db.Model):
    """14 SE-QPT Role Clusters (already exists, adding for reference)"""
    __tablename__ = 'role_cluster'

    id = db.Column(db.Integer, primary_key=True)
    role_cluster_name = db.Column(db.String(255), nullable=False)
    role_cluster_description = db.Column(db.Text, nullable=False)
```

---

## Testing Strategy

### Unit Tests
- Test AI prompt generation
- Test confidence score calculation
- Test multi-cluster mapping logic

### Integration Tests
- Test full mapping pipeline with sample roles
- Test database save/retrieve operations
- Test API endpoints

### User Acceptance Tests
- Test with real job descriptions from industry
- Validate accuracy of AI mappings
- Test edge cases (ambiguous roles, very specialized roles)

---

## Deployment Checklist

- [ ] Run migration 011 to create `organization_role_mappings` table
- [ ] Add `OrganizationRoleMapping` model to `models.py`
- [ ] Create `role_cluster_mapping_service.py`
- [ ] Add API endpoints to `routes.py`
- [ ] Create Vue components for frontend
- [ ] Test with sample organization roles
- [ ] Validate OpenAI API costs and rate limits
- [ ] Add error handling and logging
- [ ] Create user documentation
- [ ] Deploy to production

---

## Future Enhancements

1. **Batch Processing**: Process large numbers of roles in background jobs
2. **Caching**: Cache role cluster descriptions to reduce API costs
3. **Fine-tuning**: Fine-tune a custom model on validated mappings
4. **Multi-language Support**: Support role descriptions in different languages
5. **Export/Import**: Export mappings as CSV or Excel for review
6. **Confidence Threshold Settings**: Allow users to set minimum confidence scores
7. **Manual Override**: Allow users to manually adjust AI suggestions
8. **Analytics Dashboard**: Show mapping accuracy metrics over time

---

## Cost Estimation

**OpenAI API Costs** (GPT-4):
- Input: ~$0.03 per 1K tokens
- Output: ~$0.06 per 1K tokens
- Estimated cost per role mapping: $0.01 - $0.05
- For 100 roles: $1 - $5

**Development Time**:
- Backend service: 3-4 days
- API endpoints: 1-2 days
- Frontend components: 3-4 days
- Testing and refinement: 2-3 days
- **Total: 9-13 days (1.5 - 2.5 weeks)**

---

## References

1. Ulf Könemann et al., "Identification of stakeholder-specific Systems Engineering competencies for industry", SysCon 2022
2. ISO/IEC 15288:2015 - Systems and software engineering
3. INCOSE Systems Engineering Competency Framework
4. OpenAI API Documentation
